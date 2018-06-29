-- init worker
-- update rgw servers from xmsd

local timer_at = ngx.timer.at
local log = ngx.log
local ERR, INFO, DEBUG = ngx.ERR, ngx.INFO, ngx.DEBUG

local shared_jobs = ngx.shared.jobs

local utils = require "common.utils"
local log_cleanup_job = require "cron.log_cleanup"
local config_job = require "cron.config"

local jobs = {
    log_cleanup_job,
    config_job
}

local new_check = function (job)
    local check
    check = function(premature)
        if premature then
            return
        end

        local wid = ngx.worker.id()

        if job.singleton then
            -- no need for singleton job to always lock if there is no other workers
            -- run this job any more from the second round
            -- check shared dict to avoid trying lock job.name
            local v = shared_jobs:get(job.name)
            if not v or v ~= wid then
                local lock, err = utils.lock(job.name)
                if not lock then
                    log(ERR, "failed to get lock ", job.name, ": ", err)
                else
                    local unregistered = false
                    local v = shared_jobs:get(job.name)
                    log(DEBUG, "got shared job ", job.name, ": ", v)
                    if v and v ~= wid then
                        unregistered = true
                    else
                        local ok, err = shared_jobs:set(job.name, wid)
                        if not ok then
                            log(ERR, "failed to set shared jobs for ", job.name)
                        else
                            log(DEBUG, "set shared job ", job.name, " to worker ", wid)
                        end
                    end
                    local ok, err = lock:unlock()
                    if not ok then
                        log(ERR, "failed to unlock ", job.name, ": ", err)
                    else
                        log(DEBUG, "unlocked ", job.name)
                    end
                    if unregistered then
                        -- return here to unregister job since no more timer will be created
                        log(DEBUG, "unregistered ", job.name, " from worker ", wid)
                        return
                    end
                end
            end
        end

        job.run()

        -- always add timer to make cron job run infinitely
        local ok, err = timer_at(job.delay, check)
        if not ok then
            log(ERR, "failed to create timer: ", err)
            return
        end
    end
    return check
end

for _, job in ipairs(jobs) do
    if not (job.enabled == false) then
        local ok, err = timer_at(0, new_check(job))
        if not ok then
            log(ERR, "failed to register job ", job.name, ": ", err)
        else
            log(INFO, "registered job ", job.name, ", run every ", job.delay, " seconds")
        end
    else
        log(INFO, "job ", job.name, " is disabled")
    end
end


-- spawn health checker for rgw servers

local upstream = require "upstream"

local ok, err = upstream.spawn_checker()
if not ok then
    log(ERR, "failed to spawn health checker: ", err)
    return
end

-- cleanup logs

local string = require "string"
local postgres = require "postgres"

local utils = require "common.utils"
local config = require "config"

local log = ngx.log
local ERR, DEBUG, INFO = ngx.ERR, ngx.DEBUG, ngx.INFO

local sql = [[delete from s3_log where current_timestamp - create_time >= interval '%s']]

local run = function ()

    local pg, err = postgres.new()
    if not pg then
        ngx.log(ngx.ERR, "failed to new pg instance: ", err)
        return
    end

    local res, err = pg:query(string.format(sql, config.DB_LOG_EXPIRED_TIME))
    if not res then
        ngx.log(ngx.ERR, "failed to delete logs: ", err)
        return
    else
        log(INFO, "deleted " .. (res.affected_rows or 0) .. " logs in db")
    end

    local ok, err = pg:keepalive()
    if not ok then
        ngx.log(ngx.ERR, "failed to set pg keepalive: ", err)
        return
    end
end

local _M = {
    run = run,
    delay = 3600,
    name = "log_cleanup",
    singleton = true
}
if not config.LOG_CLEANUP_CRON_ENABLED then
    _M.enabled = false
end

return _M

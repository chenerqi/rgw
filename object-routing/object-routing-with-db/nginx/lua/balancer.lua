-- set current peer of upstream

local balancer = require "ngx.balancer"

local utils = require "common.utils"
local balancers = require "balancers"

local log = ngx.log
local ERR, DEBUG = ngx.ERR, ngx.DEBUG

-- we need to do our best to optimise performance in this phase
-- prevent from doing operations that consume resources like acquiring locks or 
-- network requests, try to check vars in memory instead

local ok, err = balancers:reinit()
if not ok then
    if err == "empty" then
        log(DEBUG, "peers are empty")
        -- FIXME(guojian): client still gets 500 even if we set 502 here
        return ngx.exit(ngx.HTTP_BAD_GATEWAY)
    end
    log(ERR, "failed to reinit balancers: ", err)
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local up_balancer = balancers:current_balancer()
if not up_balancer then
    log(ERR, "current balancer not found")
    -- ngx.exit is asynchronous in balancer_by_lua*, always use return to exit immediately
    return ngx.exit(ngx.HTTP_BAD_GATEWAY)
end

local server_id = up_balancer:next()
log(DEBUG, "got peer: ", server_id)
if not server_id then
    log(ERR, "peer not found")
    return ngx.exit(ngx.HTTP_BAD_GATEWAY)
end

-- roundrobin id is equal to peer
local ok, err = balancer.set_current_peer(server_id)
if not ok then
    log(ERR, "failed to set current peer: ", err)
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- update stats
local k = balancers:current_name() .. "_" .. server_id
ngx.shared.counter:incr(k, 1, 0)

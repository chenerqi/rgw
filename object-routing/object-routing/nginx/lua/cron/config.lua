-- update rgw servers

local config = require "config"

local log = ngx.log
local ERR, DEBUG = ngx.ERR, ngx.DEBUG

local run = function ()
    if not config:has_newer_version() then
        return
    end
    local ok, err = config:refresh()
    if not ok then
        log(ERR, "failed to refresh config: ", err)
    else
        log(DEBUG, "refreshed config")
    end
end

_M = {
    run = run,
    delay = 10,  -- run @every 10 seconds
    name = "config"
}

return _M

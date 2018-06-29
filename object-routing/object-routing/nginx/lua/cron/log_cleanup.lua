-- cleanup logs
local config = require "config"

local run = function ()
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

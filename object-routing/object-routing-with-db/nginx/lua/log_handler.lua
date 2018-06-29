-- log handlers

local postgres = require "postgres"
local config = require "config"

local _M = { _VERSION = '0.0.1' }

function _M.pg_handler(premature, log)

    local pg, err = postgres.new()
    if not pg then
        ngx.log(ngx.ERR, "failed to new pg instance: ", err)
        return
    end

    local res, err = pg:add_log(log)
    if not res then
        ngx.log(ngx.ERR, "failed to add s3 log: ", err, "\n", log)
        return
    end

    local ok, err = pg:keepalive()
    if not ok then
        ngx.log(ngx.ERR, "failed to set pg keepalive: ", err)
        return
    end

end

function _M.default(premature, log)
end

return _M

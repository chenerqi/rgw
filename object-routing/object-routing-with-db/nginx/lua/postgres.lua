-- lib to operate postgres

local pgmoon = require "pgmoon"
local string = require "string"
local config = require "config"

local log, DEBUG = ngx.log, ngx.DEBUG

local keepalive_timeout = 60000 -- 60s
local keepalive_size = 10 -- pool size per worker

local _M = { _VERSION = '0.0.1' }

local add_log_sql = [[
    INSERT INTO "s3_log"(uri, bucket, object, method, content_length, resp_code, resp_body, duration)
    VALUES(%s, %s, %s, %s, %d, %d, %s, %.3f)
]]

function _M.new()
    local opts = {
        host = config.DB_HOST,
        port = config.DB_PORT,
        database = config.DB_NAME,
        user = config.DB_USER,
        password = config.DB_PASSWORD
    }
    local pg = pgmoon.new(opts)
    local connected, err = pg:connect()
    if not connected then
        return nil, err
    end
    local t = setmetatable({ pg = pg }, { __index = _M })
    return t, nil
end

function _M.query(self, sql)
    log(DEBUG, "query sql: ", sql)
    return self.pg:query(sql)
end

function _M.keepalive(self)
    return self.pg:keepalive(keepalive_timeout, keepalive_size)
end

local function quote(s)
    return ndk.set_var.set_quote_pgsql_str(s)
end

local _string_with_max_length = function (s, len)
    return string.sub(s, 1, len)
end

function _M.add_log(self, log)
    local sql = string.format(add_log_sql,
        quote(_string_with_max_length(log.uri, 1024)),
        quote(_string_with_max_length(log.bucket, 1024)),
        quote(_string_with_max_length(log.object, 1024)),
        quote(log.method),
        log.content_length or 0,
        log.resp_code or 0,
        quote(_string_with_max_length(log.resp_body, 512)),
        log.duration or 0)
    return self.pg:query(sql)
end

return _M

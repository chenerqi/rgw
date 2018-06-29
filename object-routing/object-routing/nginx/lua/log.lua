-- save history of s3 requests into postgresql

local string = require "string"

local utils = require "common.utils"
local s3_log = require "common.s3_log"
local config = require "config"

-- local v = {
--     upstream_response_time = ngx.var.upstream_response_time,
--     upstream_status = ngx.var.upstream_status
-- }

-- ngx.var.bytes_received will be added in nginx v1.11.4
-- local bytes_received = ngx.var.bytes_received
local bytes_sent = ngx.var.bytes_sent

ngx.shared.stats:incr(tostring(ngx.status), 1, 0)
-- ngx.shared.stats:incr("bytes_received", bytes_received, 0)
ngx.shared.stats:incr("bytes_sent", bytes_sent, 0)

if ngx.status < 400 then
    ngx.shared.stats:incr("success", 1, 0)
else
    ngx.shared.stats:incr("failure", 1, 0)
end

-- log handler is disabled by default
if not config.LOG_HANDLER_ENABLED then
    return
end

local timer_at = ngx.timer.at

local method_name = ngx.req.get_method()
if utils.contains(utils.ignored_methods, method_name) then
    return
end

local uri = ngx.var.uri
if utils.ends_with(uri, "/") then
    uri = string.sub(uri, 1, -2)
end
if utils.starts_with(uri, "/") then
    uri = string.sub(uri, 2)
end

local bucket = uri
local object = ""

local i = string.find(uri, "/")
if i then
    bucket = string.sub(uri, 1, i-1)
    object = string.sub(uri, i+1)
end

local log = s3_log.new({
    uri = ngx.var.request_uri,
    bucket = bucket,
    object = object,
    method = method_name,
    content_length = ngx.var.content_length,
    resp_code = ngx.status,
    resp_body = ngx.var.resp_body or "", -- resp_body is disabled
    duration = ngx.var.request_time
})

function handler(premature, log)
end

-- use ngx.timer.at since cosocket is disabled in log_by_lua_* context, but enabled in timer
-- refer to: https://github.com/openresty/lua-nginx-module#cosockets-not-available-everywhere
local ok, err = timer_at(0, handler, log)
if not ok then
    ngx.log(ngx.ERR, "failed to call ngx.timer.at: ", err)
    return
end

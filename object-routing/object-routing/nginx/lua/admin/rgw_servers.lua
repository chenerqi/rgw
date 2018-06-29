-- update rgw servers on shared.dict and save into conf

local cjson = require "cjson"

local utils = require "common.utils"
local rgw_servers = require "config.rgw_servers"
local config = require "config"

local method = ngx.req.get_method()
if not utils.contains({"PUT", "GET"}, method) then
    return ngx.exit(ngx.HTTP_NOT_ALLOWED)
end

if method == "GET" then
    ngx.header.content_type = 'application/json'
    ngx.print(tostring(rgw_servers))
    return ngx.exit(ngx.HTTP_OK)
end

local log = ngx.log
local DEBUG, INFO, ERR = ngx.DEBUG, ngx.INFO, ngx.ERR

if config.UPSTREAM_REFRESH_ENABLED == false then
    log(DEBUG, "ignore updating rgw servers since upstream_refresh_enabled is false")
    return ngx.exit(ngx.HTTP_OK)
end

-- request body format: {["10.0.0.1:7480"] = 1}
ngx.req.read_body()
local data = ngx.req.get_body_data()
if not data then
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local servers = cjson.decode(data)
if not servers then
    ngx.say("invalid request body")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
if utils.table_length(servers) == 0 then
    ngx.say("servers should not be empty")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

if rgw_servers:has_newer_version() then
    local ok, err = rgw_servers:refresh()
    if not ok then
        log(ERR, "failed to refresh rgw servers: ", err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

local prev_servers = rgw_servers:data()

if utils.tables_equal(servers, prev_servers) then
    return ngx.exit(ngx.HTTP_NO_CONTENT)
end

log(INFO, "rgw servers changed: ", cjson.encode(prev_servers), " -> ", cjson.encode(servers))

rgw_servers:update_all(servers)

local ok, err = rgw_servers:save()
if not ok then
    log(ERR, "failed to write servers config: ", err)
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
log(INFO, "saved servers config")

return ngx.exit(ngx.HTTP_NO_CONTENT)

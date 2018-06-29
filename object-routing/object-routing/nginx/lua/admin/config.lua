-- update global config and save into conf

local cjson = require "cjson"
local utils = require "common.utils"
local config = require "config"

local method = ngx.req.get_method()
if not utils.contains({"PUT", "GET", "PATCH"}, method) then
    return ngx.exit(ngx.HTTP_NOT_ALLOWED)
end

if method == "GET" then
    ngx.header.content_type = 'application/json'
    ngx.print(tostring(config))
    return ngx.exit(ngx.HTTP_OK)
end

local log = ngx.log
local DEBUG, INFO, ERR = ngx.DEBUG, ngx.INFO, ngx.ERR

-- request body format: {["config1"] = value1, ["config2"] = value2}
ngx.req.read_body()
local data = ngx.req.get_body_data()
if not data then
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local data = cjson.decode(data)
if not data then
    ngx.say("invalid request body")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

if config:has_newer_version() then
    local ok, err = config:refresh()
    if not ok then
        log(ERR, "failed to refresh config: ", err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

local new_config = cjson.decode(cjson.encode(config:data()))
for k, v in pairs(data) do
    new_config[k] = v
end

if utils.tables_equal(new_config, config:data()) then
    return ngx.exit(ngx.HTTP_NO_CONTENT)
end

config:update(data)

local ok, err = config:save()
if not ok then
    log(ERR, "failed to write admin config: ", err)
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
log(INFO, "saved admin config")

return ngx.exit(ngx.HTTP_NO_CONTENT)

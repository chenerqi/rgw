-- show stats

local cjson = require "cjson"
local string = require "string"

local up = require "upstream"

local show_all = false
local args = ngx.req.get_uri_args()
for k in pairs(args) do
    if k == "all" then
        show_all = true
    end
end

local m = {}
local keys = ngx.shared.counter:get_keys()
for _, k in ipairs(keys) do
    local c = ngx.shared.counter:get(k)
    local i = string.find(k, "_")
    if i then
        local prefix = string.sub(k, 1, i-1)
        local name = string.sub(k, i+1)
        if not m[prefix] then
            m[prefix] = {}
        end
        local v = c
        local peers_up = up.get_peers_up(prefix)
        local peers_down = up.get_peers_down(prefix)
        if peers_up[name] then
            v = "up:" .. v
            m[prefix][name] = v
        elseif peers_down[name] then
            v = "down:" .. v
            m[prefix][name] = v
        elseif show_all then
            v = "n/a:" .. v
            m[prefix][name] = v
        end
    end
end

local s = {status = {}}
keys = ngx.shared.stats:get_keys()
for _, k in ipairs(keys) do
    if tonumber(k) then
        s["status"][k] = ngx.shared.stats:get(k)
    else
        s[k] = ngx.shared.stats:get(k)
    end
end

ngx.header.content_type = 'application/json'
ngx.print(cjson.encode({upstreams = m, stats = s}))
return ngx.exit(ngx.HTTP_OK)

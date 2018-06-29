-- 

local cjson = require "cjson"

local config = require "config"
local rgw_servers = require "config.rgw_servers"
local hc = require "upstream.healthcheck"

local log = ngx.log
local ERR, DEBUG = ngx.ERR, ngx.DEBUG

local dict_upstream = ngx.shared.upstream

local default_up = "default"
local upstream_peers = {}
local rgw_version = 0

local _M = { _VERSION = "0.0.1", default_up = default_up }

local new_peer = function (name, weight, is_backup)
    return {
        id = name,
        name = name,
        weight = weight,
        down = false,
        is_backup = is_backup,
        init = true
    }
end

local new_default_peers = function (servers)
    local peers = {}
    -- servers: {[127.0.0.1:7480] = 1}
    for name, weight in pairs(servers) do
        peers[name] = new_peer(name, weight, false)
    end
    return peers
end

local init_upstream = function ()
    local servers = rgw_servers:copy_data()
    local peers = new_default_peers(servers)
    upstream_peers[default_up] = peers
    local ok, err = dict_upstream:add("l:" .. default_up, true, 3)
    if not ok then
        if err == "exists" then
            return
        end
    end
    dict_upstream:set("v:" .. default_up, 0)
    local primary = {}
    for _, peer in pairs(peers) do
        primary[peer.name] = peer.weight
    end
    dict_upstream:set("u:" .. default_up, cjson.encode(primary))
    log(DEBUG, "inited upstream ", default_up, " with ", cjson.encode(primary))
end

local update_default_peers = function ()
    local version, servers, err = rgw_servers:latest_version_data()
    if not servers then
        log(ERR, "failed to get rgw servers: ", err)
        return
    end
    if rgw_version >= version then
        return
    end
    log(DEBUG, "upstream rgw version changed: ", rgw_version, " -> ", version)
    rgw_version = version
    local new_peers = new_default_peers(servers)
    local cur_peers = upstream_peers[default_up]
    if not cur_peers then
        log(DEBUG, "default upstream not found")
        return
    end
    for k in pairs(new_peers) do
        local p = cur_peers[k]
        if p then
            new_peers[k].down = p.down
        end
    end
    upstream_peers[default_up] = new_peers
end

local get_peers_map = function (u, update)
    if update and u == default_up then
        update_default_peers()
    end
    return upstream_peers[u]
end

local get_primary_peers = function (u)
    -- get primary peers of upstream named u
    local m = get_peers_map(u, true)
    if not m then
        return {}
    end
    local peers = {}
    local i = 1
    for name, peer in pairs(m) do
        if not peer.is_backup then
            peers[i] = peer
            i = i + 1
        end
    end
    return peers
end

local get_backup_peers = function (u)
    -- get backup peers of upstream named u
    local m = get_peers_map(u, true)
    if not m then
        return {}
    end
    local peers = {}
    local i = 1
    for name, peer in pairs(m) do
        if peer.is_backup then
            peers[i] = peer
            i = i + 1
        end
    end
    return peers
end

local set_peer_down = function (u, is_backup, id, value)
    -- set peer down
    local m = upstream_peers[u]
    if not m then
        return nil, "upstream " .. u .. " not found"
    end
    local peer = m[id]
    if not peer then
        return nil, "peer " .. id .. " not found in upstream " .. u
    end
    m[id].down = value
    return true
end

local notify = function (ctx)
    -- nofity if any of peers changed
    dict_upstream:set("v:" .. ctx.upstream, ctx.version)
    local primary_peers = ctx.primary_peers
    local primary_up, primary_down = {}, {}
    for _, peer in ipairs(primary_peers) do
        if not peer.down then
            primary_up[peer.name] = peer.weight
        else
            primary_down[peer.name] = peer.weight
        end
    end
    dict_upstream:set("u:" .. ctx.upstream, cjson.encode(primary_up))
    dict_upstream:set("d:" .. ctx.upstream, cjson.encode(primary_down))
    log(DEBUG, "notify upstream ", ctx.upstream, ": version=", ctx.version,
        ", primary up=", cjson.encode(primary_up), ", primary down=", cjson.encode(primary_down))
    -- TODO(guojian): update backup peers
end

local get_upstreams = function ()
    -- get a list of the names for all the named upstream groups
    local upstreams = {}
    local i = 1
    for k in pairs(upstream_peers) do
        upstreams[i] = k
        i = i + 1
    end
    return upstreams
end

function _M.version(u)
    local k = dict_upstream:get("v:" .. u)
    return k or 0
end

function _M.get_peers_up(u)
    local s = dict_upstream:get("u:" .. u)
    if not s then
        return {}
    end
    return cjson.decode(s)
end

function _M.get_peers_down(u)
    local s = dict_upstream:get("d:" .. u)
    if not s then
        return {}
    end
    return cjson.decode(s)
end

function _M.spawn_checker(u)
    u = u or default_up
    log(DEBUG, "spawn checker for upstream ", u)
    return hc.spawn_checker({
        shm = "healthcheck",  -- defined by "lua_shared_dict"
        upstream = u,
        
        get_primary_peers = get_primary_peers,
        get_backup_peers = get_backup_peers,
        set_peer_down = set_peer_down,
        notify = notify,

        type = "http",
        http_req = "GET / HTTP/1.0\r\n\r\n",
                -- raw HTTP request for checking

        interval = 5000,  -- run the check cycle every 5 sec
        timeout = 4000,   -- 1 sec is the timeout for network operations
        fall = 1,  -- # of successive failures before turning a peer down
        rise = 1,  -- # of successive successes before turning a peer up
        valid_statuses = {200, 302},  -- a list valid HTTP status code
        concurrency = 10,  -- concurrency level for test requests
    })
end

function _M.status_page()
    return hc.status_page({
        get_upstreams = get_upstreams,
        get_primary_peers = get_primary_peers,
        get_backup_peers = get_backup_peers
    })
end

init_upstream()

return _M

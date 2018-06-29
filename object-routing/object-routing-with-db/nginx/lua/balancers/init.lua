-- upstream instance for eos/aws/oss etc.

local cjson = require "cjson"
local roundrobin = require "resty.roundrobin"

local utils = require "common.utils"
local up = require "upstream"

local log = ngx.log
local ERR, DEBUG = ngx.ERR, ngx.DEBUG

-- TODO(guojian): add chash
local strategy = roundrobin

local _M = { _VERSION = '0.0.1' }

local mt = { __index = _M }

function _M.new(opts)
    -- local opts = opts or {}
    local self = {}
    self.name = up.default_up
    self.version = -1 -- set -1 to init from upstream
    self.balancers = {}
    return setmetatable(self, mt)
end

function _M.current_name(self)
    return self.name
end

function _M.current_balancer(self)
    return self.balancers[self.name]
end

local init_balancer = function (self, name, peers)
    local balancer, err = strategy:new(peers)
    if not balancer then
        log(ERR, "failed to new balancer strategy instance: ", err)
        return
    end
    log(DEBUG, "init balancer with ", cjson.encode(peers))
    self.balancers[name] = balancer
end

function _M.reinit(self)
    local name = self:current_name()
    local up_version = up.version(name)
    if up.version(name) <= self.version then
        return true
    end
    local peers = up.get_peers_up(name)
    if not peers then
        log(ERR, "peers not found")
        return
    end
    if utils.table_length(peers) == 0 then
        return nil, "empty"
    end

    log(DEBUG, "update balancer version: " .. self.version .. " -> " .. up_version)
    self.version = up_version
    local balancer = self:current_balancer()
    if not balancer then
        init_balancer(self, name, peers)
    else
        log(DEBUG, "reinit balancer with ", cjson.encode(peers))
        balancer:reinit(peers)
    end
    return true
end

return _M

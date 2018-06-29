-- base config

local utils = require "common.utils"
local cjson = require "cjson"

local log = ngx.log
local ERR, DEBUG = ngx.ERR, ngx.DEBUG

local shared_config = ngx.shared.config

local tostring = function (self)
    local m = {
        data = self._data,
        path = self.path,
        name = self.name,
        version = self.version
    }
    return cjson.encode(m)
end

local _M = { _VERSION = "0.0.1", data = {} }
local mt = { __index = _M, __tostring = tostring }

local update = function (self, m)
    for k, v in pairs(m) do
        self[k] = v
        self._data[k] = v
    end
end

function _M.new(opts)
    local self = {
        _data = {},
        path = opts.path,
        name = opts.name,
        version = 0,
        shm_key = opts.name,
        shm_version_key = opts.name .. "_version"
    }
    local m, err = utils.load_config(self.path)
    if not m then
        log(DEBUG, "failed to load config: ", err)
        m = {}
    end
    log(DEBUG, "loaded config: ", cjson.encode(m))
    update(self, m)
    shared_config:add(self.shm_version_key, self.version)
    shared_config:set(self.shm_key, cjson.encode(self._data))
    return setmetatable(self, mt)
end

function _M.update(self, m)
    update(self, m)
end

function _M.update_all(self, m)
    -- TODO(guojian): remove key from self
    update(self, m)
    self._data = m
end

function _M._lock(self)
    return utils.lock(self.shm_version_key)
end

function _M.save(self)
    local lock, err = self:_lock()
    if not lock then
        return false, err
    end
    local new_version, err = shared_config:incr(self.shm_version_key, 1, 0)
    if not new_version then
        return false, err
    end
    self.version = new_version
    local success, err = shared_config:set(self.shm_key, cjson.encode(self:data()))
    if not success then
        return false, err
    end
    local ok, err = utils.write_config(self:data(), self.path)
    if not ok then
        return false, err
    end
    ok, err = lock:unlock()
    if not ok then
        return false, err
    end
    return true
end

function _M.has_newer_version(self)
    local v = shared_config:get(self.shm_version_key)
    if not v then
        return false
    end
    return v > self.version
end

function _M.data(self)
    return self._data
end

-- create new instance as data but without reference to it
function _M.copy_data(self)
    return cjson.decode(cjson.encode(self:data()))
end

function _M.latest_data(self)
    local data, err = shared_config:get(self.shm_key)
    if not data then
        return nil, err
    end
    return cjson.decode(data)
end

function _M.latest_version_data(self)
    local lock, err = self:_lock()
    if not lock then
        return nil, nil, "failed to lock: " .. err
    end
    local version, err = shared_config:get(self.shm_version_key)
    if not version then
        return nil, nil, "failed to get " .. self.shm_version_key .. ": " .. err
    end
    local data, err = shared_config:get(self.shm_key)
    if not data then
        return nil, nil, "failed to get " .. self.shm_key .. ": " .. err
    end
    local ok, err = lock:unlock()
    if not ok then
        return nil, nil, "failed go unlock: " .. err
    end
    return version, cjson.decode(data)
end

function _M.refresh(self)
    local lock, err = self:_lock()
    if not lock then
        return false, err
    end
    local version, err = shared_config:get(self.shm_version_key)
    if not version then
        return false, err
    end
    self.version = version
    local data, err = shared_config:get(self.shm_key)
    if not data then
        return false, err
    end
    self:update_all(cjson.decode(data))
    local ok, err = lock:unlock()
    if not ok then
        return false, err
    end
    return true
end

return _M

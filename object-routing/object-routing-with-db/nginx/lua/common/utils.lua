-- common utils

local string = require "string"
local resty_lock = require "resty.lock"

local ipairs = ipairs
local tonumber = tonumber
local io = io

local log, DEBUG = ngx.log, ngx.DEBUG

local _M = { _VERSION = '0.0.1' }

local my_locks = "my_locks"

_M.or_dir = "/opt/sds/object-routing"
_M.ignored_methods = {"GET", "HEAD", "OPTIONS"}

function _M.contains(items, item)
    for _, v in ipairs(items) do
        if v == item then
            return true
        end
    end
    return false
end

local function _starts_with(s, sub)
   return string.sub(s, 1, string.len(sub)) == sub
end
_M.starts_with = _starts_with

local function _ends_with(s, sub)
   return sub =='' or string.sub(s, -string.len(sub)) == sub
end
_M.ends_with = _ends_with

-- check if two arrays are equal
local _arrays_equal
_arrays_equal = function(a1, a2)
    if #a1 ~= #a2 then
        return false
    end
    for i in ipairs(a1) do
        if a1[i] ~= a2[i] then
            return false
        end
    end
    return true
end

_M.arrays_equal = _arrays_equal

function _M.tables_equal(t1, t2)
    local a1, a2 = {}, {}
    for k in pairs(t1) do
        table.insert(a1, k)
    end
    table.sort(a1)
    for k in pairs(t2) do
        table.insert(a2, k)
    end
    table.sort(a2)
    if not _arrays_equal(a1, a2) then
        return false
    end
    for k in pairs(t1) do
        if t1[k] ~= t2[k] then
            return false
        end
    end
    return true
end

function _M.table_length(t)
    local c = 0
    for k in pairs(t) do
        c = c + 1
    end
    return c
end

function _M.load_config(path)
    local f, err = io.open(path, "r")
    if not f then
        return nil, err
    end
    local m = {}
    for line in f:lines() do
        if not _starts_with(line, "#") then
            local i = string.find(line, "=")
            if i then
                local k, v = string.sub(line, 1, i-1), string.sub(line, i+1)
                -- make compatible to shell style
                if (_starts_with(v, "\"") and _ends_with(v, "\""))
                    or (_starts_with(v, "'") and _ends_with(v, "'")) then
                    v = string.sub(v, 2, -2)
                end
                -- convert to build in type
                if string.lower(v) == "true" then
                    v = true
                elseif string.lower(v) == "false" then
                    v = false
                elseif tonumber(v) then
                    v = tonumber(v)
                end
                m[k] = v
            end
        end
    end
    f:close()
    return m
end

function _M.write_config(m, path)
    local f, err = io.open(path, "w+")
    if not f then
        return nil, err
    end
    for k, v in pairs(m) do
        f:write(k .. "=" .. tostring(v) .. "\n")
    end
    f:flush()
    f:close()
    return true, nil
end

function _M.lock(key)
    local lock, err = resty_lock:new(my_locks)
    if not lock then
        return nil, "new lock err: " .. err
    end

    local elapsed, err = lock:lock(key)
    if not elapsed then
        return nil, err
    end

    log(DEBUG, "acquired ", key, " lock after ", elapsed, " seconds")
    return lock
end

return _M

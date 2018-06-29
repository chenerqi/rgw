-- models

local string = require "string"
local cjson = require "cjson"

local _M = {}

local function tostring(self)
    return cjson.encode(self)
end

function _M.new(arg)
    return setmetatable(arg, { __index = _M, __tostring = tostring })
end

return _M
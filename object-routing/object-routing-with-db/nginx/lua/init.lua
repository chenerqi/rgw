-- init global variable

local log = ngx.log
local ERR, DEBUG = ngx.ERR, ngx.DEBUG

local _balancers = require "balancers"

local balancers, err = _balancers.new()
if not balancers then
    return ngx.ERROR
end
package.loaded["balancers"] = balancers

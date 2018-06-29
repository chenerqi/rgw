-- rgw servers config

local utils = require "common.utils"
local base = require "config.base"

local servers_config_path = utils.or_dir .. "/conf/load-balancer-servers.conf"

return base.new({name = "servers", path = servers_config_path})

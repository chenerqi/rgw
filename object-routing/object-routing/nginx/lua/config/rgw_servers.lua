-- rgw servers config

local utils = require "common.utils"
local base = require "config.base"

local servers_config_path = utils.or_dir .. utils.servers_config_dir

return base.new({name = "servers", path = servers_config_path})

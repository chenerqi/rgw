-- global config

local utils = require "common.utils"
local base = require "config.base"

local config_path = utils.or_dir .. "/conf/object-routing.conf"

return base.new({name = "config", path = config_path})

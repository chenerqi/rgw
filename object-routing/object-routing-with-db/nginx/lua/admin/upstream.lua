-- show upstreams with peers status

local up = require "upstream"

ngx.say("Nginx Worker PID: ", ngx.worker.pid())
ngx.print(up.status_page(up))

local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local max_client = 64

skynet.start(function()
	print("Main Server start")
	skynet.uniqueservice("protoloader")
    local loginserver = skynet.newservice("logind")
    local gate = skynet.newservice("gated", loginserver)
    skynet.call(gate, "lua", "open", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
        servername = "sample",
    })
	
	print("Main Server exit")
	skynet.exit()
end)

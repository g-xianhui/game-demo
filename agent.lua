REQUEST = {}
userdata = {}
local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
require "role"

local host
local send_request

local gate
local userid, subid
local CMD = {}
local client_fd
local database

function get_platform_id()
    return userid
end

function get_db_handler()
    return database
end

function REQUEST:handshake()
    -- send back userdata, maybe load at login time
	return { msg = "Welcome to skynet." }
end

-- client send heartbeat every x second, and if recv no response after y second, connection had down
function REQUEST:heartbeat()
    return {}
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

local function logout()
    -- just check which part is dirty, item for test
    skynet.call(database, "lua", "save_item", userdata.rolesimple.role_id, userdata.items)
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK"))
    skynet.call(database, "lua", "save_item", userdata.rolesimple.role_id, userdata.items)
end

function CMD.start(source, fd, uid, sid, secret)
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	client_fd = fd

	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	-- load user data from database
    userdata = skynet.call(database, "lua", "load_all", uid)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = CMD[command]
        if session > 0 then
		    skynet.ret(skynet.pack(f(source, ...)))
        else
            f(source, ...)
        end
	end)
	database = skynet.uniqueservice("database")
end)

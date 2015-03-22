package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;game-demo/?.lua"

require "client_login"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local socket = require "clientsocket"
local proto = require "proto"
local sproto = require "sproto"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

-- { msg name : process functions }
local MSG = {}
-- { session : process function }
local session_response = {}
local fd

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	send_package(fd, str)
	print("Request:", session)
    if MSG[name] then
        session_response[session] = MSG[name]
    end
end

local last = ""

local function print_request(name, args)
	print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
    
    if MSG[name] then
        MSG[name](args)
    end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
    if session_response[session] then
        session_response[session](args)
        session_response[session] = nil
    end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end

		print_package(host:dispatch(v))
	end
end

fd = login()

function MSG.rolesimple(msg)
    print("rolesimple reply")
    for k, v in pairs(msg.data) do
        print(k, v)
    end
    if not msg.data.name then
        send_request("create_role", {name = "fortest", occ = 2})
    end
end

function MSG.create_role(msg)
    print("create role reply: " .. msg.result)
end

function MSG.item_add(msg)
    print("item add reply: " .. msg.result)
end

send_request("handshake")
send_request("heartbeat")
send_request("rolesimple", { role_id = 0 })

send_request("item_add", { item_id = 4, count = 2 })
send_request("item_data")
while true do
	dispatch_package()
	local cmd = socket.readstdin()
	if cmd then
        print(cmd)
		-- send_request("get", { what = cmd })
	else
		socket.usleep(100)
	end
end

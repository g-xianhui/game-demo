local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local socketdriver = require "socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local loginservice = tonumber(...)

local servername
local users = {}
local username_map = {}
local connection = {}
local handshake = {}
local internal_id = 0

local handler = {}

local function username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
local function login_handler(uid, secret)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local username = username(uid, internal_id, servername)

    local agent = skynet.newservice "agent"
	local u = {
		secret = secret,
		username = username,
		uid = uid,
		subid = internal_id,
        agent = agent
	}

	-- trash subid (no used)

	users[uid] = u
	username_map[username] = u
    print("username add: " .. username)

	-- you should return unique subid
	return internal_id
end

-- call by agent
local function logout_handler(uid, subid)
	local u = users[uid]
	if u then
		users[uid] = nil
		username_map[u.username] = nil
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
        print("username del: " .. u.username)
		skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

-- call by login server
local function kick_handler(uid, subid)
	local u = users[uid]
	if u then
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

local CMD = {
    login = login_handler,
    logout = logout_handler,
    kick = kick_handler,
}

function handler.command(cmd, source, ...)
    local f = assert(CMD[cmd])
    return f(...)
end

function handler.open(source, conf)
    servername = assert(conf.servername)
    skynet.call(loginservice, "lua", "register_gate", servername, skynet.self())
end

function handler.connect(fd, addr)
	skynet.error("New client from : " .. addr .. " " .. fd)
    handshake[fd] = addr
    gateserver.openclient(fd)
end

-- call by self (when socket disconnect)
function handler.disconnect(fd)
	local u = connection[fd]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

-- not so nice
local function auth(fd, addr, msg, sz)
    local result = nil
    local message = netpack.tostring(msg, sz)
	local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")

    print("auth username: " .. username)
    local u = username_map[username]
    if u == nil then
        result = "404 User Not Found"
    end

	hmac = b64decode(hmac)
    local text = string.format("%s:%s", username, index)
    local v = crypt.hmac64(crypt.hashkey(text), u.secret)
    if v ~= hmac then
        result = "401 Unauthorized"
    end

    if result then
        socketdriver.send(fd, netpack.pack(result))
	    gateserver.closeclient(fd)
    else
		u.fd = fd
        connection[fd] = u

        -- you can use a pool to alloc new agent
	    skynet.call(u.agent, "lua", "start", fd, u.uid, u.subid, u.secret)

        socketdriver.send(fd, netpack.pack("200 OK"))
    end
end

function handler.message(fd, msg, sz)
    local addr = handshake[fd]
    if addr then
        auth(fd, addr, msg, sz)
        handshake[fd] = nil
    else
        local u = connection[fd]
        -- return skynet.tostring(skynet.rawcall(u.agent, "client", msg, sz))
		skynet.redirect(u.agent, 0, "client", 0, msg, sz)
    end
end

gateserver.start(handler)


local skynet = require "skynet"
local mysql = require "mysql"
local assert = assert

local function print_t(t)
    for k, v in pairs(t) do
        print(k, v)
        if type(v) == "table" then
            print_t(v)
        end
    end
end

local function get_role_id(db, uid)
    local res = db:query('select account_id from account where platform_id = "' .. uid .. '"') 
    if #res == 0 then
        -- test
        db:query('insert into account(platform_id) values("' .. uid .. '")')
        res = db:query('select account_id from account where platform_id = "' .. uid .. '"') 
    elseif res.errno then
        skynet.error(res.err)
        return
    end

    return res[1].account_id
end

local function load_role_simple(db, role_id)
    local res = db:query('select * from rolesimple where role_id = "' .. role_id .. '"')
    return #res == 0 and {role_id = role_id} or res[1]
end

local function load_item(db, role_id)
    local res = db:query('select * from item where role_id = "' .. role_id .. '"')
    return res
end

local CMD = {}
function CMD.load_all(db, uid)
    local role_id = get_role_id(db, uid)
    if not role_id then return end
    
    local userdata = {}
    userdata.rolesimple = load_role_simple(db, role_id)
    userdata.items = load_item(db, role_id)
    return userdata
end

function CMD.save_role_simple(db, role)
    db:query(string.format('insert into rolesimple(role_id, name, level, occupation) values(%d, "%s", %d, %d)',
                            role.role_id, role.name, role.level, role.occupation))
end

function CMD.save_item(db, role_id, items)
    local res = db:query('delete from item where role_id = "' .. role_id .. '"')
    for _, v in ipairs(items) do
        local str = string.format("%d, %d, %d, %d", role_id, v.guid, v.item_id, v.count) 
        db:query('insert into item(role_id, guid, item_id, count) values(' .. str .. ')')
    end
end

skynet.start(function ()
	local db = mysql.connect {
		host = "127.0.0.1",
		port = 3306,
		database = "test",
		user = "root",
		password = "",
		max_packet_size = 1024 * 1024
	}
    if not db then
        error("failed to connect")
    end
    db:query("set names utf8")

	skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        assert(f, string.format("command[%s] not found", command))
        skynet.retpack(f(db, ...))
    end)
end)

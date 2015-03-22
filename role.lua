local skynet = require "skynet"

function REQUEST:rolesimple()
    if self.role_id == 0 then
        return { data = userdata.rolesimple }
    else
        return {}
    end
end

function REQUEST:create_role()
    if userdata.rolesimple.name then
        return { result = "already have role" }
    else
        -- params check, test ignore
        userdata.rolesimple.name = self.name
        userdata.rolesimple.level = 1
        userdata.rolesimple.occupation = self.occ 
        local db = get_db_handler()
        skynet.call(db, "lua", "save_role_simple", userdata.rolesimple)
        return { result = "ok" }
    end
end

function REQUEST:item_data()
    return { data = userdata.items }
end

local function get_item_guid(items)
    table.sort(items, function(l, r) return l.guid < r.guid end)
    local i = 1
    for k, v in ipairs(items) do
        if v.guid ~= i then
            return i
        end
        i = i + 1
    end
    return i
end

function REQUEST:item_add()
    print("item_add", self.item_id, self.count)
    local item = {}
    item.guid = get_item_guid(userdata.items)
    item.item_id = self.item_id
    item.count = self.count
    if userdata.items then
        userdata.items[#userdata.items + 1] = item
    else
        userdata.items = { item }
    end
    return { result = "ok" }
end


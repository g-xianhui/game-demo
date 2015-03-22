local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

heartbeat 2 {
    response {}
}

.RoleSimple {
    role_id 0 : integer
    name 1 : string
    level 2 : integer
    occupation 3 : integer
}
rolesimple 3 {
    request {
        role_id 0 : integer
    }
    response {
        data 0 : RoleSimple
    }
}

.Item {
    id 0 : integer
    count 1 : integer
}
item_data 4 {
    response {
        data 0 : *Item
    }
}

item_add 5 {
    request {
        item_id 0 : integer
        count 1 : integer
    }
    response {
        result 0 : string
    }
}

create_role 6 {
    request {
        name 0 : string
        occ 1 : integer
    }
    response {
        result 0 : string
    }
}
]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}
]]

return proto

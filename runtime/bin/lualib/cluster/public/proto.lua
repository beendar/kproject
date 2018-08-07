local strpack   = string.packx
local strunpack = string.unpackx
local pbencode  = require 'pb.core'.encode
local pbdecode  = require 'pb.core'.decode

local HEADER_SIZE     = 14
local PTYPE_RESPONSE  = 0
local PTYPE_HEARTBEAT = 1
local PTYPE_LUA       = 2
local PTYPE_PROTOBUF  = 3
local EMPTY = {}


local proto = {
	packmsg = function(id, handle, session, msg, len)
		 return strpack('IHIIp', HEADER_SIZE+len, id, handle, session, msg, len)
	end,
}

local function register(p)
	proto[p.id] = p
	proto[p.name] = p
end


register {
	name = 'response',
	id   = PTYPE_RESPONSE,
}

register {
	name = 'heartbeat',
	id   = PTYPE_HEARTBEAT,
	pack = function() return nil, 0 end,
	unpack = function() end
}

register {
	name   = 'lua',
	id     = PTYPE_LUA,
	pack   = require'lnet.seri'.pack,
	unpack = require'lnet.seri'.unpack,
}

local function callback(buffer, len, name)
    return strpack('sp', name, buffer, len)
end

register {
	name = 'pb',
	id = PTYPE_PROTOBUF,
	pack = function(name, t)
		if not name then return nil, 0 end
        return pbencode(name, t or EMPTY, callback, name)
	end
	, unpack = function(msg, len)
        local name,msg,len = strunpack('s', msg, len)
		return name, pbdecode(name, msg, len)
	end
}


return proto

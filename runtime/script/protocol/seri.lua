local strpackx = string.packx
local pbencode = require 'pb.core'.encode
local pbdecode = require 'pb.core'.decode
local host = require 'protocol.host'


local function callback(buffer, length)
	return strpackx('p', buffer, length)
end

local function pack(key, data, dir)
    local p = host.query(key)
    return p.id, pbencode(p[dir], data, callback)
end

local function unpack(key, msg, len, dir)
    local p = host.query(key)
    return p.name, pbdecode(p[dir], msg, len)
end


return {
    pack = pack,
    unpack = unpack,
}
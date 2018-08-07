local dictionaryc = require 'cluster.dictionaryc'

local error = error
local tonumber = tonumber

local shared = {}
local empty = table.readonly()

local typekey = {
	user = 'location:user',
	clan = 'location:clan',
	clanroom = 'location:clanroom',
}

local function ensurekey(type)
	local key = typekey[type]
	if not key then
		local errmsg = ('invalid location type: %s'):format(type)
		error(errmsg, 3)
	end
	return key
end

local function pack(addr, handle)
	shared.addr = addr
	shared.handle = handle
	return shared
end


local location = {}

function location.set(type, field, addr, handle)
	local key = ensurekey(type)
	dictionaryc.hset(key, field, pack(addr,handle))
end

function location.setnx(type, field, addr, handle)
	local key = ensurekey(type)
	return dictionaryc.hsetnx(key, field, pack(addr,handle))
end

function location.unset(type, field)
	local key = ensurekey(type)
	dictionaryc.hdel(key, field)
end

function location.get(type, field, strict)
	local key = ensurekey(type)
	local r = dictionaryc.hget(key, field)
	return (r and r) or (not strict and empty)
end


return location
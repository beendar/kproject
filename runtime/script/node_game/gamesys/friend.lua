local bson = require 'database.mongo.bson'
local mongo = require 'lnet'.env'db'

local type = type
local pairs = pairs
local ipairs = ipairs
local assert = assert

local collbase = mongo:getcol'base'
local collfriend = mongo:getcol'friend'

local empty = {}

local friendmax = require'metadata'.gamecommon[1].friends_max


local function make(owner, friendbase, status)
	return {
		pid = owner,
		rgnid = friendbase.rgnid,
		fpid = friendbase.pid,
		status = status or 1,
		ap_ti = 0,

		nickname = friendbase.nickname,
		headid = friendbase.headid,
		mask = friendbase.mask,
		plv = friendbase.plv,
		medal = friendbase.medal,
		online = friendbase.online,
		offline = friendbase.offline
	}
end

local function simplify(entry)
	entry.nickname = nil
	entry.headid = nil
	entry.mask = nil
	entry.plv = nil
	entry.medal = nil
	entry.online = nil
	entry.offline = nil
	return entry
end


local friendsys = {
	make = make,
	simplify = simplify
}

function friendsys.find(pid, rgnid)
	local cond = { pid=pid, rgnid=rgnid }
	local selector = { _id=0, pid=1, nickname=1, headid=1, plv=1 }
	return collbase:find_one(cond, selector)
end

function friendsys.check(source, target)
	assert(target ~= '', 'target pid is invalid')
	assert(source.pid ~= target, 'try adding self as friend')
	assert(not source.model.base:friendfull(), 'your friend list is full')

	-- make friend entry from source, if not add yet
	local cond = { pid=target, rgnid=source.rgnid, fpid=source.pid }

	if collfriend:count(cond) == 0 then
		return make(target, source.model.base)
	end
end

function friendsys.add(entry, strict)
	local cond = { pid=entry.pid, rgnid=entry.rgnid }
	local modify = { ['$inc']={sysfriendn=1} }

	if strict then
		cond.sysfriendn = { ['$lt']=friendmax }
		if collbase:find_modify(cond, {_id=0,rgnid=1}, modify) then
			collfriend:insert(simplify(entry))
		end
	else
		collbase:update(cond, modify)
		collfriend:insert(simplify(entry))
	end
end

function friendsys.remove(owner, rgnid, target)
	collbase:update({pid=owner,rgnid=rgnid}, {['$inc']={sysfriendn=-1}})
	collfriend:remove { pid=owner, rgnid=rgnid, fpid=target }
end

function friendsys.formation(pid, rgnid)

	-- load role id list
	local cond = { pid=pid, rgnid=rgnid, methodid=1 }
	local selector = { 
		_id=0, 
		['formation.1']=1, ['formation.2']=1, ['formation.3']=1,
		['formation.4']=1, ['formation.5']=1, ['formation.6']=1,
	}

	local r = mongo:getcol'pmethod':find_one(cond, selector)
	if not r or not r.formation then 
		return 
	end

	-- load roles
	local cond = { pid=pid, rgnid=rgnid, tid={['$in']=bson.array(r.formation)} }
	local selector = { _id=0, tid=1, level=1, quality=1, skill=1, stone=1 }
	local rolelist = mongo:getcol'role':find(cond, selector):totable'tid'

	-- collect stone sn
	local stonesn = {}
	for _,role in pairs(rolelist) do
		for _,sn in ipairs(role.stone) do
			stonesn[#stonesn+1] = (sn > 0) and sn or nil
		end
	end

	-- load stones
	local cond = { pid=pid, rgnid=rgnid, sn={['$in']=bson.array(stonesn)} }
	local selector = { _id=0, pid=0, rgnid=0 }
	local stonelist = mongo:getcol'stone':find(cond, selector):toarray()
	
	-- arrange roles at correct position
	local arranged = {}
	for i,tid in ipairs(r.formation) do
		arranged[i] = rolelist[tid] or empty
	end

	return arranged, stonelist
end


return friendsys
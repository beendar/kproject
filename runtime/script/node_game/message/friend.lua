local cluster = require 'cluster.slave'
local location = require 'pub.location'
local friendsys = require 'gamesys.friend'

local assert = assert

local HANDLER = {}

HANDLER['FindPlayer'] = function(u, req)
	return { base = friendsys.find(req.target, u.rgnid) }
end

HANDLER['MakeFriend'] = function(u, req)
	local entry = friendsys.check(u, req.target)
	if entry then
		local pos = location.get('user', req.target)
		local ok = cluster.send(pos, 'lua', '.MakeFriendForward', entry)
   		if not ok then friendsys.add(entry, true) end
   end
end

HANDLER['.MakeFriendForward'] = function(u, entry)
	local agent = u.agent
	local model = u.model
	if entry.status == 0 or not model.base:friendfull() then
		agent:send('MakeFriendForward', {friend=entry})
		model.base:incfriendn(1)
		model.friend[entry.fpid] = friendsys.simplify(entry)
	end
end

HANDLER['MakeFriendApply'] = function(u, req)
	local obj = u.model.friend[req.source]
	assert(not obj:check(), 'this guy has been your friend')
	if obj:apply(req.ok) then
		local entry = friendsys.make(req.source, u.model.base, 0)
		local pos = location.get('user', req.source)
		local ok = cluster.send(pos, 'lua', '.MakeFriendForward', entry)
		if not ok then friendsys.add(entry, false) end
	end
end

HANDLER['DeleteFriend'] = function(u, req)
	local obj = u.model.friend[req.target]
	assert(obj:check(), 'this guy has not complete been your friend')
	obj:remove()

	local pos = location.get('user', req.target)
	local ok = cluster.send(pos, 'lua', '.DeleteFriend', u.pid)
	if not ok then friendsys.remove(req.target, u.rgnid, u.pid) end
end

HANDLER['.DeleteFriend'] = function(u, target)
	u.model.friend[target]:remove()
	u.agent:send('DeleteFriendForward', {fpid=target})
end

HANDLER['FindFormation'] = function(u, req)
	local role,stone = friendsys.formation(req.target, u.rgnid)
	return { role=role, stone=stone }
end


return HANDLER
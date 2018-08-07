local log = require 'log'
local lnet = require 'lnet'
local gate = require 'cluster.public.gate'
local dispatch = require 'cluster.public.dispatch'

local ACTIVE  = {}
local PASSIVE = {}
local PENDING = {}


local function notify(node, addr, direction, action)
	local tip = ('[%s]: %s conn %s'):format(node, direction, action)
	log.print(tip)
	local _,_,type = node:find'(%w+)@'
	lnet.send(direction..'.'..action, addr, type)
	lnet.send(type..'.'..action, addr, type)
	lnet.send(string.format('%s.%s.%s', type, direction, action), addr)
end

local function wakeuppending(host, ...)
	for _, session in ipairs(PENDING[host]) do
		local ok,errmsg = lnet.resume(session, ...)
		if not ok then log.error(errmsg) end
	end
	PENDING[host] = nil
end

local function open(host, ptype, chance)
	local peer,errmsg = gate.open(host, ptype, chance)
	ACTIVE[host] = peer
	wakeuppending(host, peer, errmsg)
	if peer then
		notify(peer.node, host, 'active', 'made')
			peer:heartbeat()
			peer:start(dispatch.message, peer)
			peer:close()
	        ACTIVE[host] = nil
		notify(peer.node, host, 'active', 'broken')
	end
end

local function ensure(host, ptype, chance)
	local peer = ACTIVE[host] or PASSIVE[host]
	if peer then
		return peer
	end
	if not host then
		return nil, 'invalid host address'
	end
	local backlog = PENDING[host]
	if not backlog then
		backlog = {}
	    PENDING[host] = backlog
		lnet.fork(open, host, ptype or 'lua', chance or math.huge)
	end
	if #backlog > 128 then
		return nil, 'pending list is maximum'
	end
	backlog[#backlog+1] = lnet.genId()
	return lnet.wait()
end

local function getcobj(host)
	local peer = ACTIVE[host] or PASSIVE[host]
	return peer and peer:handle() or nil
end

local function welcome(peer)
	local node = peer.node
	local addr = peer.addr
	PASSIVE[addr] = peer
	notify(node, addr, 'passive', 'made')
		peer:heartbeat()
		peer:start(dispatch.message, peer)
		peer:close()
	notify(node, addr, 'passive', 'broken')
	PASSIVE[addr] = nil
end

local fd
local function startup()
	fd = gate.watch(lnet.env'iendpt', welcome)
end


return {
	startup = startup,
	ensure  = ensure,
	getcobj = getcobj,
}

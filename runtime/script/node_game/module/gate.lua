local lnet = require 'lnet'
local cluster = require 'cluster.slave'
local codecache = require 'codecache'
local online = require 'module.online'

local os = os
local table = table
local assert = assert


local HANDLER = {}

HANDLER['LoginGameServer'] = function(sock, req)
	local pid = req.pid
	local rgnid = req.rgnid
	assert(#pid > 0, 'invalid pid')
	assert(rgnid > 0, 'invalid rgnid')

	-- makesure that last login operation has been completed of user
	if online.pending(pid) then
        return { opcode=1 }, true
	end

	-- begin loading userdata from database
	local secret = os.time()
	local addr, handle = cluster.gensul()

	local model = codecache.call('object.model', pid, rgnid)
	local agent = codecache.call('object.agent', sock, secret)
	local user  = codecache.call('object.user',  pid, rgnid, secret, model, agent, addr, handle)

	-- try kicking last user object
	-- and put new one into online list(also removing entry from pending list)
	online.kick(pid, 'relogin', '')
	online.startsession(user)

	-- update userdata and make response
	model:start()

	return table.copy({ pid=pid, secret=secret }, model.archive)
end

HANDLER['ReconnectGameServer'] = function(sock, req)
	local ok = online.restartsession(req.pid, req.secret, sock)
	local shutdown = not ok
	return { ok=ok }, shutdown
end


local function startup()

	-- inital online module
	online.start()

	-- register to clustermaster
	cluster.register('game.gate', os.pid(), lnet.env'xendpt')

	-- start listener for game client
	local clientlistener = require 'pub.clientlistener'

	listenfd = clientlistener.start {
		host = lnet.env'ixendpt',
		secret = 'secret',
		dispatch = function(sock, cmd, req)
			return HANDLER[cmd](sock, req)
		end
	}

end


return {
	startup = startup
}
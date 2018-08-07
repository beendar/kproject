local log = require 'log'
local lnet = require 'lnet'
local socket = require 'socket'

local pairs = pairs

local ctx,pid,rgnid,host,lsecret = ...

local sock
local conn_secret
local sess_secret
local session = 0
local session_coroutine = {}


local function dispatch(name, data, session)
	local co = session_coroutine[session]
	session_coroutine[session] = nil
	if co then
		assert(lnet.resume(co, data))
	else
		local handler = require 'handler'
        assert(lnet.fork(handler, ctx, name, data))
	end
end

local function loop(sock)
	local ok,errmsg = true,nil
	for name,data,session in sock:start() do
		ok,errmsg = lnet.fork(dispatch, name, data, session)
		if not ok then
			log.error(errmsg)
		end
	end
	sock:close()
	log.error('vclient[%s]: socket error', pid)	
end

local function heartbeat(sock)
	lnet.timeout(5, math.huge, function()
		return sock:send('Heartbeat', {}, 0)
	end)
end


local inst = {}

function inst.open()
	local s,r = socket.open(host, lsecret, 
		'LoginGameServer', {
			pid = pid, 
			rgnid = rgnid, 
			secret = lsecret
		})
	assert(s, 'gameconn: connect to remote host FAILED')
	sock = s
	conn_secret = r.secret
    sess_secret = r.secret
	lnet.fork(function()
        heartbeat(sock)
		loop(sock)
		inst.reopen()
    end)
    return r
end

function inst.reopen()
	local s,r = socket.open(host, conn_secret,
		'ReconnectGameServer', {
			pid = pid,
			secret = conn_secret
		})
	assert(s, 'gameconn: reconnect to remote host FAILED')
	sock = s
	log.print('vclient[%s]: reconnect gameserver [%s]', pid, r.ok and 'OK' or 'FAILED')
	if r.ok then
		heartbeat(sock)
		loop(sock)
		inst.reopen()
	else
		sock:close()
	end
end

function inst.call(name, req)
	local secret = sess_secret + 9973
	sess_secret = secret 
	session = session + 1
	session_coroutine[session] = lnet.genId()
	sock:send(name, req, session, secret)
	return lnet.wait() 
end


return inst
local log = require 'log'
local lnet = require 'lnet'
local cluster = require 'cluster.slave'
local location = require 'pub.location'
local linger = require 'module.linger'
local dispatchc = require 'message.dispatchc'

local os = os

local usercnt
local userlist = {}
local pendinglist = {}


local function _enter(u)
	-- setup s2s message proxy 
	cluster.dispatch(u.handle, function(_, ...) return dispatchc(u, ...) end)
	-- update location in cluster
	location.set('user', u.pid, u.addr, u.handle)
	-- update module local status
	usercnt = usercnt + 1
	userlist[u.pid] = u
end

local function _exit(u)
	cluster.dispatch(u.handle, nil)
	location.unset('user', u.pid)
	usercnt = usercnt - 1
	userlist[u.pid] = nil
end

local function startsession(u)
	_enter(u)
	local ok, errmsg = u:start(dispatchc)
	u:stop('runtime', errmsg, ok)
	-- put user object into linger list if there is no runtime error
	-- and waiting for reconnecting in a period
	if ok then linger.add(u.pid, u) end
	_exit(u)
	-- print an error log for detail
	log.error('user %s exit with error:\n\t%s', u.pid, errmsg)
end


local online = {}

function online.pending(pid)
	local now = os.time()
	local expire = pendinglist[pid]
	if not expire or now >= expire then
		pendinglist[pid] = now + 20
		return false
	end
	return true
end

function online.count()
	return usercnt
end

function online.get(pid)
	return userlist[pid]
end

function online.startsession(u)
	pendinglist[u.pid] = nil
	-- try remove entry from linger list(may be fully login)
	linger.remove(u.pid) 
	-- start session
	lnet.fork(startsession, u)
end

function online.restartsession(pid, secret, sock)
	local u = linger.remove(pid)
	if u and u:reconnect(secret, sock) then
		online.startsession(u)
		return true
	end
end

function online.kick(pid, reason, message)
	local u = userlist[pid]
	if u then
		_exit(u)
		local reason  = reason or 'kicked'
		local message = message or 'you are kicked by gamemaster'
		u:stop(reason, message)
	end
end

function online.start()
	usercnt = 0
	linger.start(function(u)
		u:stop()
	end)
end


return online
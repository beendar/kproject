local lnet      = require 'lnet'
local sockdriver = require 'lnet.sockdriver'
local proto     = require 'cluster.public.proto'
local dispatch  = require 'cluster.public.dispatch'
local sockmngr  = require 'cluster.public.sockmngr'

local table = table
local type = type
local ipairs = ipairs
local pairs = pairs
local assert = assert

local SID = 100
local directoryd = 1
local directoryc = 2

local MASTER     = lnet.env'clustermaster'.iendpt
local MYADDR     = lnet.env'iendpt'
local DIRECTORY  = table.ensure()
local REGISTERED = {}
local SUBSCRIBED = {}
local NAMELOOK   = {}


function show( ... )
	dump(DIRECTORY)
end

local function notify(type, action, ...)
	lnet.send(type..'.'..action, ...)
end

local function transform(_, s)
	s.name = s.addr..':'..s.handle
end

--!@param:
--	context			(pass by local dispath)
--  method name     (from remote node)
--  message         (from remote node)
local function update(_, _, msg) 
	local mode = msg.mode
	local type = msg.type
	local list = table.foreach(msg.list, transform)
	local dict = DIRECTORY[type]
	if mode == 'add' then
		table.append(dict, list,
			function(s)
				local exists = NAMELOOK[s.name]
				NAMELOOK[s.name] = true
				if not exists then
					notify(type, 'online', s)
					return s
				end
			end)
	elseif mode == 'remove' then
		local ok = table.removeif(dict, function(v) return v.name == list[1].name end)
		if ok then
			NAMELOOK[list[1].name] = nil
			notify(type, 'offline', list[1])
		end
	end
end

local function gensid()
	SID = SID + 1
	if SID == 0xffffffff then
		SID = 100
	end
	return SID
end

local function gensul()
	return MYADDR, gensid()
end

local function register(type, handle, extra)
	assert(not REGISTERED[handle], 'register service with same handle once more')
	local sock = sockmngr.ensure(MASTER)
	local service = { type=type, handle=handle, extra=extra }
	sock:send('lua', directoryd, 'cluster.register', service)
	REGISTERED[handle] = service
end

local function registerx(stype, sid, callback)
	local idtype = type(sid)
	local cbtype = type(callback)
	local ok = idtype == 'number' and cbtype == 'function' or idtype == 'function'
	assert(ok, 'invalid parameters when register')
	if idtype == 'function' then
		callback = sid
		sid = gensid()
	end
	register(stype, sid)
	dispatch.dispatch(sid, callback)
end

local function subscribe(type)
	local sock = sockmngr.ensure(MASTER)
	local sub = { type=type }
    update(nil, sock:call('lua', directoryd, 'cluster.subscribe', sub) )
	SUBSCRIBED[type] = sub
	return (#DIRECTORY[type] > 0)
end

local function query(type, mode, ...)
	local list = DIRECTORY[type]
	if #list == 0 then return end
	mode = mode or 'random'
	if mode == 'random' then
		return list[math.random(1, #list)]
	elseif mode == 'mod' then
		local nonce = ...
		return list[nonce % #list + 1]
	elseif mode == 'all' then
		return list
	end
end

local function wait(type, mode, ...)
	if not query(type, mode, ...) then
		while not subscribe(type) do
			lnet.sleep(1)
		end
	end
	return query(type, mode, ...)
end

local function touch(service, ptype, chance)
	return sockmngr.ensure(service.addr, ptype, chance)
end

local function call(service, ptype, ...)
	local sock,errmsg = sockmngr.ensure(service.addr, ptype, 1)
	if sock then
		return sock:call(ptype, service.handle, ...)
	end
	return nil, errmsg
end

local function send(service, ptype, ...)
	local sock,errmsg = sockmngr.ensure(service.addr, ptype, 1)
	if sock then
		sock:send(ptype, service.handle, ...)
		return true
	end
	return nil, errmsg
end

local function socklist(var)
	local r = {}
	-- var is service typename
	if type(var) == 'string' then
		for _,s in ipairs(DIRECTORY[var]) do
			r[#r+1] = sockmngr.getcobj(s.addr)
		end
	-- var is address table
	elseif type(var) == 'table' then
		for _,addr in pairs(var) do
			r[#r+1] = sockmngr.getcobj(addr)
		end
	end
	return r
end

local function multisend(var, handle, ptype, ...)
	local list = socklist(var)
	if #list == 0 then return end
	local p = assert(proto[ptype], ptype)
	local msg,len = proto.packmsg(p.id, handle, 0, p.pack(...))
	sockdriver.broadcast('q', list, msg, len)
end

local function multicall(var, handle, ptype, ...)
	local list = socklist(var)
	if #list == 0 then return end
	local p = assert(proto[ptype], ptype)
	local msg,len = proto.packmsg(p.id, handle, lnet.genId(), p.pack(...))
	sockdriver.broadcast('q', list, msg, len)
	local r = {}
	for n=1, #list do
		table.grab(r, p.unpack(lnet.wait()))
	end
	return r
end

local function newservice(modname, ...)
	local sid = gensid()
	local stype,callback,extra = require(modname).launch(...)
	assert(type(stype) == 'string')
	assert(type(callback) == 'function')
	register(stype, sid, extra)
	dispatch.dispatch(sid, callback)
end

local function activebroken(addr)
	for type,list in pairs(DIRECTORY) do
		for idx=#list, 1, -1 do
			local service = list[idx]
			if service.addr == addr then
				NAMELOOK[service.name] = nil
				table.remove(list, idx)
				notify(type, 'offline', service)
				-- validate to clustermaster, whether this service is truely offline
				local sock = sockmngr.ensure(MASTER)
				sock:send('lua', directoryd, 'cluster.validate', type, service.name)
			end
		end
	end
end

local function clustermasterbroken()
	local reg = REGISTERED
	REGISTERED = {}
	table.foreach(reg, function(_, s)
		register(s.type, s.handle, s.extra)
	end)
	table.foreach(SUBSCRIBED, function(type)
		subscribe(type)
	end)
end

local function concern(event, callback)
	lnet.pipe(event, callback)
end

local function startup()
	sockmngr.startup()
	dispatch.dispatch(directoryc, update)
	concern('active.broken', activebroken)
	concern('clustermaster.broken', clustermasterbroken)
end


return {
	startup    = startup,
	register   = register,
	registerx  = registerx,
	subscribe  = subscribe,
	query      = query,
	wait       = wait,
	touch      = touch,
	call       = call,
	send       = send,
	multisend  = multisend,
	multicall  = multicall,
	gensid     = gensid,
	gensul     = gensul,
	newservice = newservice,
	concern    = concern,
	dispatch   = dispatch.dispatch,
}
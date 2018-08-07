local log = require 'log'
local lnet = require 'lnet'
local proto = require 'cluster.public.proto'
local sockhelper = require 'sockhelper'

local read = sockhelper.read
local write = sockhelper.write
local assert = assert
local setmetatable = setmetatable


local socket = {}
setmetatable(socket, socket)
socket.__index = socket
socket.__call = function(mt, fd, bsetopt)
	if bsetopt then
		sockhelper.setopt(fd, 'nodelay', 1)
		sockhelper.setopt(fd, 'opbuffer', 4096)
		sockhelper.setopt(fd, 'recvbuffer', 256*1024)
		sockhelper.setopt(fd, 'recvtimeout', 30)
		sockhelper.setopt(fd, 'sendbuffer', -1)
	end
    return setmetatable({fd=fd}, mt)
end


function socket:recv()
	local ptype, _, _, msg, len = read(self.fd)
	local p = proto[ptype]
	if p then
		return p.unpack(msg, len)
	end
end

function socket:start(callback, ctx)

	local function dispatch(ptype, handle, session, msg, len)
		local p = proto[ptype]
		if session > 0 then
			local body, size = p.pack(callback(handle,ctx,p.unpack(msg,len)))
			write(self.fd, 0, 0, session, body, size)
		else
			callback(handle, ctx, p.unpack(msg,len))
		end
	end

	for ptype,handle,session,msg,len in read, self.fd do
		-- 0 PTYPE_RESPONSE, see in public.proto
		-- 1 PTYPE_HEARTBEAT, nothing to do when recving
		if ptype == 0 then
			local ok,errmsg = lnet.resume(session, msg, len)
			if not ok then log.error(errmsg) end
		elseif ptype > 1 then
			local ok,errmsg = lnet.fork(dispatch, ptype, handle, session, msg, len)
			if not ok then
				log.error(errmsg)
			end
		end
	end
end

function socket:send(ptype, handle, ...)
	local p = proto[ptype]
	return write(self.fd, p.id, handle, 0, p.pack(...))
end

function socket:call(ptype, handle, ...)
	local p = proto[ptype]
	write(self.fd, p.id, handle, lnet.genId(), p.pack(...))
	return p.unpack(lnet.wait())
end

function socket:check()
	return sockhelper.check(self.fd)
end

function socket:heartbeat()
	lnet.timeout(10, math.huge, function()
		return self:send('heartbeat', 0)
	end)
end

function socket:handle()
	return self.fd
end

function socket:close()
	sockhelper.close(self.fd)
end


local function connect(host)
	local fd = sockhelper.connect(host)
	if fd then
		return socket(fd, true)
	end
end

local function listen(host, callback)
	local listenfd = 
	sockhelper.listen(host, function(fd)
		callback(socket(fd,true))
	end)
	return socket(listenfd)
end


return {
	connect = connect,
	listen = listen,
}
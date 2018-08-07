local log = require 'log'
local sockhelper = require 'sockhelper'
local seri = require 'protocol.seri'
local encrypt = require 'protocol.encrypt'

local assert = assert
local pcall = pcall
local xpcall = xpcall
local traceback = debug.traceback
local setmetatable = setmetatable


local socket = {}
setmetatable(socket, socket)

socket.__index = socket
socket.__tostring = function(sock)
    return sock.fd
end
socket.__call = function(mt, fd)
    return setmetatable({
        fd = fd,
        lasterror = 'sockerror'
    }, mt)
end


function socket:recv()
	local id,sign,session,body,len = sockhelper.read(self.fd)
	-- skip socket error
    if id then
    	-- hearbeat, skip decoding
        if id == 1 then
        	return 'Heartbeat', nil, session
		end
		-- decode buffer in protect mode
        local ok,name,req = pcall(seri.unpack, id, body, len, 'S')
        if not ok then
            self.lasterror = 'unpack message failed'
            return
        end
        -- verify signature
        local secret = self.gensecret(req)
        if not encrypt.validate(sign, secret, body, len) then
            self.lasterror = 'malformed signature'
            return 
		end
		-- unpack message succeed
      	return name, req, session
    end
end

function socket:send(name, data, session, shutdown)
    local id, msg, len = seri.pack(name, data, 'C')
    return sockhelper.write(self.fd, id, 0, session, msg, len, shutdown)
end

function socket:start(gensecret)
	self.gensecret = gensecret
	return self.recv, self
end

function socket:close()
    sockhelper.close(self.fd, true)
end

function socket:issockerror()
    return (self.lasterror == 'sockerror')
end

function socket:getlasterror()
    return self.lasterror
end


local function start(param)
    local host = assert(param.host, 'host not set')
    local secret = assert(param.secret, 'secret not set')
    local dispatch = assert(param.dispatch, 'dispatch func not set')
    local opbuffer = param.opbuffer or 128
    local recvbuffer = param.recvbuffer or 1024
    local recvtimeout = param.recvtimeout or 20
    local function gensecret(req)
        return req[secret]
    end
    local listenfd = sockhelper.listen(host, function(fd)
		-- apply socket options
        sockhelper.setopt(fd, 'opbuffer', opbuffer)
        sockhelper.setopt(fd, 'recvbuffer', recvbuffer)
		sockhelper.setopt(fd, 'recvtimeout', recvtimeout)
		-- wrap fd as socket object
        local sock = socket(fd)
		sock.gensecret = gensecret
		-- recv client request
        local name,req,session = sock:recv()
        if not name then
            log.error( sock:getlasterror() )
            return sock:close()
		end
		-- dispatch client request
		local ok,r,shutdown = xpcall(dispatch, traceback, sock, name, req)
		if not ok then
			log.error(r)
			return sock:close()
		end
		-- send back response
		sock:send(name, r, session, shutdown)
		-- close socket if it is tail sending
        if shutdown then 
            sock:close() 
        end
    end)
    return socket(listenfd)
end


return {
    start = start
}
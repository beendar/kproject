local sockhelper = require 'sockhelper'
local seri = require 'protocol.seri'
local encrypt = require 'protocol.encrypt'

local read = sockhelper.read
local write = sockhelper.write

local pcall = pcall
local assert = assert
local setmetatable = setmetatable


local socket = {}
socket.__index = socket
socket.__tostring = function(sock)
    return sock.fd
end

function socket:recv()
	-- is socket error
    local id,sign,session,body,len = read(self.fd)
    if not id then
        return
	end
	-- is decode error
    local ok,name,req = pcall(seri.unpack, id, body, len, 'C')
    if not ok then
        return
	end
    return name, req, session
end

function socket:send(name, data, session, secret)
    local id, msg, len = seri.pack(name, data, 'S')
    local sign = encrypt.sign(secret or 0, msg, len)
    return write(self.fd, id, sign, session, msg, len)
end

function socket:start()
	return self.recv, self
end

function socket:close()
    sockhelper.close(self.fd)
end


return {
    open = function(host, secret, cmd, req)
        local fd = sockhelper.connect(host)
        if not fd then return end
        sockhelper.setopt(fd, 'opbuffer', 1024)
        sockhelper.setopt(fd, 'recvbuffer', 256*1024)
        sockhelper.setopt(fd, 'recvtimeout', 30)
        local sock = setmetatable({fd=fd}, socket)
        sock:send(cmd, req, 0, secret)
        local _, r = sock:recv()
    	return sock, r
    end
}
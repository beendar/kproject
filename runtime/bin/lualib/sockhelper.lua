--!@brief: send and recv message has specific header as follow:
--!@    header {
--!@       uint32, -- must be length field, show full length of msg
--!@       uint16,
--!@       uint32,
--!@       uint32
--!@    }


local sockdriver = require 'lnet.sockdriver'

local send = sockdriver.send
local recv = sockdriver.recv
local pack = string.packx
local unpack = string.unpackx

local HSIZE   = 14
local RHEADER = 'IHII'
local WHEADER = 'IHIIp'


local sockhelper = setmetatable({}, {__index=sockdriver})

function sockhelper.read(fd)
    local header = recv(fd, HSIZE)
	if header then
	    local len,h1,h2,h3 = unpack(RHEADER, header, HSIZE)
		local body,size = recv(fd, len-HSIZE)
		if body then
			return h1, h2, h3, body, size
		end
    end
end

function sockhelper.write(fd, h1, h2, h3, body, size, shutdown)
	size = size or 0
	local msg, len = pack(WHEADER, HSIZE+size, h1, h2, h3, body, size)
	return send(fd, msg, len, shutdown)
end


return sockhelper
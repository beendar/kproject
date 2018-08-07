local lnet = require 'lnet'
local proto = require 'chatproto'
local sockdriver = require 'lnet.sockdriver'

local assert = assert

-- start message loop
local fd = assert(sockdriver.udp'0', 'create chat socket failed')

assert(lnet.fork(function()
	for msg,len in sockdriver.recvfrom, fd do
		local ok,cmd,data = pcall(proto.unpack, msg, len)
		if ok then
			local tip = ('recving chat message: %s - len %d'):format(cmd, len)
			dump(data, tip)
		else
			print('chat incorrect recved msg', cmd)
		end
	end
	sockdriver.close(fd)
end))


local room = {}

local chatconn = {}


function chatconn.add(channel, one)
	room[channel] = one
	lnet.timeoutx(1, 15, math.huge, chatconn.say, channel)
	dump(one, 'chatroom info')
end

function chatconn.say(channel, content)
    local one = assert(room[channel], 'has not been joined yet')
    local secret = one.secret
	local msg,len = proto.pack('ChatSaying', {
		pid = one.pid,
		secret = secret,
		content = content,
	}, secret)
	return sockdriver.sendto(fd, one.host, msg, len)
end


return chatconn
local badword = require 'badword.core'
local nickname = require 'pub.nickname'
local chatsys = require 'gamesys.chat'

local assert = assert

local HANDLER = {}

HANDLER['Echo'] = function(u, req)
	req.text = req.text .. ' ' .. os.time()
	return req
end

HANDLER['SetNickname'] = function(u, req)
	local ok,result = nickname.check('user', req.nn)
	if ok then
		u.model.base:setnickname(req.nn)
	end
	return { opcode=result }
end

HANDLER['SetSignature'] = function(u, req)
	if badword.find(req.sign) then
		return { opcode=1 }
	end
	u.model.base.sign = req.sign
end

HANDLER['ChatJoinRoom'] = function(u, req)
	return chatsys.join(req.channel, u.model)
end

-- from node_interface.chatsys
HANDLER['.banchat'] = function(u, duration)
	chatsys.drop(1, u.model)
	chatsys.drop(2, u.model)
end

HANDLER['DailyBuy'] = function(u, req)
	local type = req.type
	local value,ti = u.model.base:dailybuy(type)
	return { value=value, next_ti=ti }
end



return HANDLER

local inst = {}

local gameconn = require'codecache'.call('gameconn', inst, ...)
local chatconn = require'codecache'.call('chatconn')

function inst.open()
	table.copy(inst, gameconn.open())
	inst.joinchat(1)
	if #inst.base.clanid > 0 then
		inst.ClanLogin()
		inst.joinchat(2)
	end
	return inst
end

function inst.joinchat(channel)
	assert(channel > 0, 'invalid chat room channel')
	chatconn.add( channel, inst.ChatJoinRoom{channel=channel} )
end

function inst.say(channel, ...)
	chatconn.say(channel, ...)
end

setmetatable(inst, { __index = function(_, cmd)
	inst[cmd] = function(msg)
		return gameconn.call(cmd, msg or {})
	end
	return inst[cmd]
end})


return inst.open()
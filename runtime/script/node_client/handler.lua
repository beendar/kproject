
local HANDLER = {}

HANDLER['Heartbeat'] = function()
end

HANDLER['SystemError'] = function(u, data)
	dump(data, '!!!!!!!!! SystemError !!!!!!!!!!!')
end

HANDLER['MakeFriendForward'] = function(u, data)
	local fpid = data.friend.fpid
	local nickname = data.friend.nickname
	local status = data.friend.status
	if status == 1 then
		local tip = ('player-%s:%s want to make friend with you'):format(nickname, fpid)
		print(tip)
		u.MakeFriendApply{ source=fpid, ok=true }
	else 
		local tip = ('player-%s:%s is your friend now'):format(nickname, fpid)
		print(tip)
	end
end


return function(u, name, data)
	local f = HANDLER[name]
	if f then
		f(u, data)
	else
		dump(data, ('SERVER PUSHED MESSAGE - %s'):format(name))
	end
end
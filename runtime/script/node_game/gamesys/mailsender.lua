local mailsys = require 'gamesys.mail'

local error = error 
local assert = assert


local filter = {}

filter['present_ap'] = function(source, target)
	local obj = source.model.friend[target]
	assert(obj and obj:check(), 'this guy is not your friend')

	local energy, next_ti = obj:present_ap()
	assert(energy, next_ti)

	return { next_ti=next_ti }
			, 86400
			, 'energy mail from friend'
			, 'your friend sent you some energy'
			, {energy=energy}
end


local mailsender = {}

function mailsender.p2p(reason, source, target, ...)

	local f = filter[reason]
	if not f then
		local errmsg = ('invalid sending reason - %s'):format(reason)
		error(errmsg, 2)
	end

	local result,
			validperiod, 
		 	title, 
		 	content, 
		 	attachment = f(source, target, ...)

	local mail = mailsys.new(source.model:genmailid()
							, source.model.base.nickname
							, validperiod
							, title
							, content
							, attachment
							, target
							, source.rgnid)

	mailsys.send(mail)

	return result
end

function mailsender.p2self(u, title, content, attachment)
	local mail = mailsys.new(u.model:genmailid()
							, '系统'
							, 3600 * 24
							, title
							, content
							, attachment
							, u.pid
							, u.rgnid)

	mailsys.send(mail)
end


return mailsender

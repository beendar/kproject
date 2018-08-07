local util = require 'gamesys.util'
local mailsys = require 'gamesys.mail'
local mailsender = require 'gamesys.mailsender'

local ipairs = ipairs



local HANDLER = {}

HANDLER['SendFriendMail'] = function(u, req)
	local reason = req.reason
	local target = req.target
	return mailsender.p2p(reason, u, target)
end

HANDLER['RetrieveMailList'] = function(u, req)
	local model = u.model

	local mails,lastsmid,lastsendtime = 
 			mailsys.pull(u.pid, u.rgnid
					, model.base.sysmailid
					, model:getvar'lastsendtime' or 0)


	model.base.sysmailid = lastsmid
	model:setvar('lastsendtime', lastsendtime)

	return { mails=mails }
end

HANDLER['RetrieveMailContent'] = function(u, req)
	return { content=mailsys.content(req.id) }
end

local function apply(model, attachment)
	if not attachment then return end

	if attachment.energy then
		model.base:addenergy(attachment.energy)
	end

	-- a list like: { {tid=1, count=1}, {tid=2, count=2}, ...}
	if attachment.item then
		model.bag:additem(attachment.item)
	end

	-- stone should be only a tid
	if attachment.stone then
		local pid = model.pid
		local rgnid = model.rgnid
		for i,tid in ipairs(attachment.stone) do
			local stone = util.newstone(pid, rgnid, tid, model:gensn())
			model.stone[stone.sn] = stone
			-- replace tid with stone instance
			attachment.stone[i] = stone
		end
	end

	return attachment
end

HANDLER['ReadMail'] = function(u, req)
	return apply(u.model, mailsys.read(u.pid, u.rgnid, req.id))
end


return HANDLER
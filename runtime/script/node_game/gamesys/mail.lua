local cjson = require 'extend.cjson'

local os = os
local math = math
local table = table
local type = type
local next = next
local ipairs = ipairs

local TEXTTYPE_DIRECT   = 0
local TEXTTYPE_CONFIG   = 1
local TEXTTYPE_RETRIEVE = 2

local INBOX = {}
local LOOKUP = {}

local collsys
local colluser

local function new(id, sender, validperiod,
					title, content, attachment,
					pid, rgnid, texttype, priority)

	-- encode attachment in json format
	-- otherwise, keeping orignal value as well:
	-- 1. already be in json(sysmail from db or multicast message)
	-- 2. nil

	if type(attachment) == 'table' then
		attachment = cjson.encode(attachment)
	end

	return {
		-- header
		id = id,
		sender = sender,
		sendtime = os.time(),
		expire = os.time() + validperiod,
		texttype = texttype,
		priority = priority,

		-- body
		title = title,
		content = content,
		attachment = attachment,

		-- receiver
		pid = pid,
		rgnid = rgnid,
	}
end

local function send(mail)
	colluser:insert(mail)
end

local function checkoutsysmail(sm, now, pid, rgnid, lastsmid)
	local ok = (sm.expire > now and sm.id > lastsmid)
		and (sm.receivers.rgnid==0 or sm.receivers.rgnid==rgnid)
		and (not next(sm.receivers.list) or sm.receivers.list[pid])
	if ok then
		return new(sm.id, sm.sender, sm.expire-now, 
			sm.title, nil, sm.attachment, 
			pid, rgnid, TEXTTYPE_RETRIEVE, sm.priority)
	end
end

local cond = { expire={}, sendtime={} }
local selector = { _id=0 }

local function pull(pid, rgnid, lastsmid, lastsendtime)
	local now = os.time()
	cond.pid = pid
	cond.rgnid = rgnid
	cond.expire['$gt'] = now
	cond.sendtime['$gt'] = lastsendtime

	-- load user mail from database
	local list = colluser:find(cond,selector):sort('sendtime',1):toarray()
	if #list > 0 then
		lastsendtime = list[#list].sendtime
	end

	-- track sysmail into usermail
	local incre = {}

 	for _,sm in ipairs(INBOX) do
		local um = checkoutsysmail(sm, now, pid, rgnid, lastsmid)
		if um then
			list[#list+1] = um
 			incre[#incre+1] = um
 			lastsendtime = math.max(lastsendtime, um.sendtime) 
		end
		if lastsmid >= sm.id then 
			break 
		end
	end

	-- insert new mails into database
	if #incre > 0 then
		lastsmid = incre[1].id
		colluser:batch_insert(incre)
	end

	return list, lastsmid, lastsendtime 
end

local cond = { read={['$exists']=false} }
local selector = { _id=0, attachment=1 }
local update = { read=true }

local function read(pid, rgnid, id)
	cond.pid = pid
	cond.rgnid = rgnid
	cond.id = id
	local r = colluser:find_modify(cond, selector, update)
	if r and r.attachment then
		return cjson.decode(r.attachment)
	end
end


local CMD = {}

CMD['remove'] = function(id)
	LOOKUP[id]= nil
	table.removeif(INBOX, function(sm) return (sm.id == id) end)
end

CMD['add'] = function(sm)
	LOOKUP[sm.id]  = sm
	table.insert(INBOX, 1, sm)
end

local function startup(driver)
	collsys  = driver:getdb'kgame':getcol'sysmail'
	colluser = driver:getdb'kgame':getcol'usermail'

	-- load system mails from database
	local cond = { expire={ ['$gt']=os.time() } }
	local selector = { _id=0 }

	local list = collsys:find(cond, selector):sort('id',-1):toarray()
	for _, sm in ipairs(list) do
		CMD.add(sm)
	end

	-- listening multicast message for operations on system mail
	local multicastc = require 'cluster.multicastc'

	multicastc.subscribe('game.opsysmail', function(op, ...)
		CMD[op](...)
		return true
	end)
end


return {
	startup = startup,
	new = new,
	send = send,
	pull = pull,
	read = read,
	content = function(id)
		local sm = LOOKUP[id]
		return sm and sm.content or nil
	end,
}
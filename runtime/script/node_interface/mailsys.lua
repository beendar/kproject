local lnet = require 'lnet'
local multicastc = require 'cluster.multicastc'

local collbase = lnet.env'gamedb':getcol'base'
local collsysmail = lnet.env'maildb':getcol'sysmail'

local itemsys = require 'itemsys'


local function checkreceivers(receivers)
	asserti(type(receivers)=='table', 'receivers: 这个字段应是json对象')
	local rgnid = receivers.rgnid
	local list = receivers.list
	asserti(type(rgnid)=='number', 'receivers.rgnid: 这个字段应是interger')
	asserti(type(list)=='table', 'receivers.list: 这个字段应是用户pid的数组')
	if rgnid > 0 and #list > 0 then
		local bson = require 'database.mongo.bson'
		local cond = {
			rgnid = rgnid,
			pid = { ['$in'] = bson.array(list) }
		}
		local fields = { _id=0, pid=1 }
		local lookup = collbase:find(cond, fields):totable'pid'
		local inexistent = {}
		for _, pid in ipairs(list) do
			if not lookup[pid] then
				table.insert(inexistent, pid)
			end
		end
		if #inexistent > 0 then
			local errmsg = string.format('下列用户ID无效: %s', table.concat(inexistent,','))
			asserti(false, errmsg)
		end
	end
end

local function checkattachment(attachment)
	if not attachment then return end
	asserti(type(attachment)=='table', 'attachment: 附件列表应是json对象')

	-- validate and transform
	local tmp = {}

	for idx, entry in pairs(attachment) do
		assert(type(entry)== 'table', '附件条目应是json对象,形如{tid:1,count:1}')
		assert(type(entry.tid)=='number', '附件条目缺少tid字段')
		assert(type(entry.count)=='number', '附件条目缺少count字段')

		local typename = itemsys.typename(entry.tid)
		assert(typename, '无效的物品ID')

		if typename == 'stone' then
			tmp.stone = tmp.stone or {}
			table.insert(tmp.stone, entry.tid)
		elseif typename == 'item' then
			tmp.item = tmp.item or {}
			table.insert(tmp.item, entry)
		else
			tmp.energy = entry.count
		end

		attachment[idx] = nil
	end

	table.copy(attachment, tmp)
end

local function checkparameters(m)
	asserti(m.optype=='add' or m.optype=='remove', 'optype: 邮件操作类型应是"add"或者"remove"')
	asserti(m.optype=='add' or m.id, 'optype: 期望移除邮件,但未指定邮件ID')

	if m.optype == 'add' then
		asserti(m.sender, 'sender: 未设置发送者')
		asserti(m.expire, 'expire: 未设置过期时间')
		asserti(m.title, 'title: 未设置邮件抬头')
		asserti(m.content, 'content: 未设置邮件正文')
		checkreceivers(m.receivers)
		checkattachment(m.attachment)
	end

	if m.optype == 'remove' then
		local n = collsysmail:count{id=m.id}
		asserti(n > 0, '邮件不存在')
	end
end


local CMD = {}

CMD['add'] = function(m)

	-- 1. generate internal id for this mail
	-- 2. set creation time
	-- 3. transform receivers.list from array to hash table, pid is the key
	m.id = string.format('sys:%d', os.time())
	m.creationtime = os.time()
	m.receivers.list = table.totable(m.receivers.list)


	-- 4. insert new mail into database
	collsysmail:insert(m)

	-- 5. notify all game node
	multicastc.send('game.opsysmail', 'add', m) 
end

CMD['remove'] = function(m)
	collsysmail:remove{id=m.id}
	multicastc.send('game.opsysmail', 'remove', m.id)
end


local mailsys = {}

function mailsys.handle(m)
	checkparameters(m)
	CMD[m.optype](m)
end

function mailsys.startup()
end


return mailsys
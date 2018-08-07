local event = require 'pub.event'
local location = require 'pub.location'
local cluster = require 'cluster.slave'
local util = require 'util'

local table = table
local pairs = pairs

local ROLE_MASTER = 4
local ROLE_MANAGER = 3
local ROLE_CORE = 2
local ROLE_NORMAL = 1
local ROLE_ZERO = 0

local EVENT_REQUEST_JOIN = 1
local EVENT_MEMBER_JOIN  = 2
local EVENT_MEMBER_QUIT  = 3
local EVENT_ROLE_CHANGE  = 4
local EVENT_BASEINFO_CHANGE = 5
local EVENT_UPGRADE = 6

local MEMBER_RIGHT = {
	[1] = {
	},
	[2] = {
		handle_req = true,
	},
	[3] = {
		start_activity = true,
		handle_req = true,
		modify_role = true,
		manage = true,
		kick = true,
	},
	[4] = {
		start_activity = true,
		handle_req = true,
		modify_name = true, -- 包含图标
		modify_sign = true,
		modify_role = true,
		delete_message = true,
		manage = true,
		kick = true,
	},
}

local CLAN_COMMON = {
	member_base = 20,
	member_inc = 2,
	manager_base = 2,
	manager_inc = 2,
	request_max = 5,
	upgradecost = 100,
}


local CMD = {}

CMD['requestjoin'] = function(self, base)
	if self:isrgnok(base.rgnid)
		and self:iscapacityok() 
		and not self.member[base.pid] 
	then
		-- 此时为待处理状态
		self:increqs(1)
		self:addmember(base.pid) 
		-- 发布公会事件
		self:raisevent(EVENT_REQUEST_JOIN, {
			pid = base.pid,
			role = ROLE_ZERO,
			score = 0,
			medal = 0,
			base = base
		})
		-- 操作成功
		return true
	end
end

CMD['handlejoin'] = function(self, src, dst, ok)
	local source = self.member[src]
	local dest   = self.member[dst]

	-- 1. 验证src的权限
	-- 2. 验证dst的状态
	if source.role == ROLE_NORMAL   -- 权限不足
		or not dest                 -- 对应条目不存在
		or dest.role > ROLE_ZERO    -- 已成为会员
		or dest.pending             -- 异步挂起
	then 
		return 
	end

	-- 3. 如果拒绝
	if not ok then
		self:increqs(-1)
		self:delmember(dst)
		return 
	end

	-- 4. 如果同意
	-- 即将执行异步操作 置该用户状态为挂起
	dest._raw.pending = true

	-- 尝试更新dst所属公会id
	-- 若该用户被其他公会先行纳入 则会失败 删除条目 并更新待处理计数
	local succ = util.updateuserclanid(dst, self.base.rgnid, self.clanid)
	if not succ then
		self:increqs(-1)
		self:delmember(dst)
		return 
	end 

	-- 否则 该用户成功成为会员
	-- 更新会员状态
	dest.role = ROLE_NORMAL
	dest.jointime = os.time()
	dest._raw.pending = nil

	--更新公会状态
	self:increqs(-1)
	self:incmbrs(1)

	-- 通告公会成员
	self:raisevent(EVENT_MEMBER_JOIN, {pid=dst})

	-- 通告这名新会员(如果在线)
	local pos = location.get('user', dst)
	cluster.send(pos, 'lua', '.ClanHandleJoin', self.clanid)
end

CMD['kick'] = function(self, src, dst)
	local source = self.member[src]
	local dest = self.member[dst]

	if source and dest
		and MEMBER_RIGHT[source.role].kick
		and dest.role > ROLE_ZERO
		and source.role > dest.role
	then
		-- 通知该玩家(如果在线)
		local pos = location.get('user', dst)
		cluster.send(pos, 'lua', '.ClanKick')
		-- 清除对方clanid
		util.cleanuserclanid(dst, self.base.rgnid)
		-- 更新公会状态
		self:incmbrs(-1)
		self:delmember(dst)
		-- 抛送公会事件
		self:raisevent(EVENT_MEMBER_QUIT, {pid=dst})
	end
end

CMD['quit'] = function(self, who)
	if self.member[who] then
		self:incmbrs(-1)
		self:delmember(who)
		self:raisevent(EVENT_MEMBER_QUIT, {pid=who})
	end
end

CMD['setrole'] = function(self, src, dst, role)
	local source = self.member[src]
	local dest   = self.member[dst]

	-- 条件检测...
	if src == dst 
		or role < ROLE_ZERO 
		or role > ROLE_MASTER
		or not source 
		or not dest
		or source.role == ROLE_ZERO 
		or dest.role == ROLE_ZERO 
		or dest.role == role
		or source.role < role
		or source.role <= dest.role 
		or not MEMBER_RIGHT[source.role].modify_role
		or (source.role == ROLE_MASTER and dest.role == ROLE_MANAGER and self:managercount() >= self:maxmanager())
	then
		return
	end

	-- 尝试更改source的角色
	local exchange = (source.role == role)
	if exchange then
		source.role = ROLE_NORMAL
	end

	-- 更改dest的角色
	dest.role = role

	-- 发布公会事件
	self:raisevent(EVENT_ROLE_CHANGE, {
		target_pid  = dst,
		target_role = role,
		source_pid  = exchange and src or nil,
		source_role = exchange and ROLE_NORMAL or nil,
	})

	return true
end

CMD['modifybaseinfo'] = function(self, src, field, value)
	local source = self.member[src]

	-- game节点已验证field,value的有效性...
	if source and source.role == ROLE_MASTER 
	then

		value = (field == 'icon' and tonumber(value)) or value
		self.base[field] = value

		self:raisevent(EVENT_BASEINFO_CHANGE, {
			field = field,
			value = value
		})
	end
end

CMD['upgrade'] = function(self, src)
	local source = self.member[src]
	local goldcost = self.base.level * CLAN_COMMON.upgradecost
	local goldleft = self.base.gold - goldcost

	if source 
		and MEMBER_RIGHT[source.role].manage 
		and goldleft >= 0
	then
		local nextlv = self.base.level + 1
		self.base.level = nextlv
		self.base.gold = goldleft

		self:raisevent(EVENT_UPGRADE, {
			level = nextlv,
			gold = goldleft
		})

		return true
	end
end

CMD['discard'] = function(self)
	cluster.dispatch(self.handle, nil)
	self.base:drop()
	self.member:drop()
	location.unset('clan', self.clanid)
end

CMD['baseinfo'] = function(self)
	return self.base._raw
end


local mt = {}
mt.__index = mt

function mt:raisevent(type, content)
	event.raise('clan', type, content, self.clanid)
end

function mt:isrgnok(rgnid)
	return (self.base.rgnid == rgnid)
end

function mt:iscapacityok()
	return (self.base.mbrs < self:maxmember() and self.base.reqs < CLAN_COMMON.request_max)
end

function mt:increqs(inc)
	local base = self.base
	base.reqs = base.reqs + inc 
	return base.reqs
end

function mt:incmbrs(inc)
	local base = self.base
	base.mbrs = base.mbrs + inc 
	return base.mbrs
end

function mt:addmember(pid)
	self.member[pid] = util.newmember(self.clanid, pid, ROLE_ZERO)
end

function mt:delmember(pid)
	self.member[pid] = nil
end

function mt:maxmember()
	local mbrbase = CLAN_COMMON.member_base
	local mbrinc = CLAN_COMMON.member_inc
	return mbrbase + self.base.level * mbrinc
end

function mt:maxmanager()
	local mngrbase = CLAN_COMMON.manager_base
	local mngrinc = CLAN_COMMON.manager_inc
	return mngrbase + self.base.level * mngrinc
end

function mt:managercount()
	local count = 0
	for _, mbr in pairs(self.member) do
		if mbr.role == ROLE_MANAGER then
			count = count + 1
		end
	end
	return count
end

function mt:start()
	-- 响应其他节点的操作请求
	local function response(self, ...)
		self.base:save()
		self.member:save()
		return ...
	end

	cluster.dispatch(self.handle, function(_, cmd, ...)
		local f = CMD[cmd]
		return response(self, f(self, ...))
	end)

	return self
end


return {
	wrap = function(data)
		return setmetatable(data, mt)
	end,
}
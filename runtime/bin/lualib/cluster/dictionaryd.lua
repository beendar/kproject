--!@brief: 主从结构的字典服务 
local lnet = require 'lnet'
local seri = require 'lnet.seri'
local zlib = require 'extend.zlib'
local cluster = require 'cluster.slave'
local arbitratec = require 'cluster.arbitratec'

local select = select
local setmetatable = setmetatable
local tinsert = table.insert
local tunpack = table.unpack

local dictionaryd = 7
local dictinternal = 8

local TRACK = {}

local function update(addr, valid)
	local tr = TRACK[addr]
	if not tr then
		tr = {}
		tr.__index = tr
		TRACK[addr] = tr
	end
	tr.__valid = valid
end

local function make(addr, value)
	return setmetatable({value=value}, TRACK[addr])
end

local H0 = {}
local H1 = table.ensure()

local CMD = {}

CMD['login'] = function(addr)
	TRACK[addr] = nil
	update(addr, true)
end

CMD['reconnect'] = function(addr)
	update(addr, true)
end

CMD['logout'] = function(addr)
	update(addr, false)
end

CMD['set'] = function(addr, key, value)
	H0[key] = make(addr, value)
end

CMD['setnx'] = function(addr, key, value)
	local entry = H0[key]
	local succeed = not entry or not entry.__valid
	if succeed then
		entry = make(addr, value)
		H0[key] = entry
	end
	return succeed, entry.value
end

CMD['del'] = function(_, key)
	H0[key] = nil
end

CMD['get'] = function(_, key)
	local entry = H0[key]
	if entry and entry.__valid then
		return entry.value
	end
	H0[key] = nil
end

CMD['hset'] = function(addr, key, field, value)
	H1[key][field] = make(addr, value)
end

CMD['hsetnx'] = function(addr, key, field, value)
	local entry = H1[key][field]
	local succeed = not entry or not entry.__valid
	if succeed then
		entry = make(addr, value)
		H1[key][field] = entry
	end
	return succeed, entry.value
end

CMD['hget'] = function(_, key, field)
	local entry = H1[key][field]
	if entry and entry.__valid then
		return entry.value
	end
	H1[key][field] = nil
end

CMD['hdel'] = function(_, key, field)
	H1[key][field] = nil
end

local function handle_command(cli, cmd, ...)
	return CMD[cmd](cli, ...)
end

local ICMD  = {}
local OPLOG = {}
local SLAVE = {}

ICMD['login'] = function(slv)
	SLAVE[slv] = slv
	--TODO: 新节点加入 需向其同步全量数据
end

ICMD['reconnect'] = function(slv)
	SLAVE[slv] = slv
end

ICMD['wsync'] = function(_, len, data)
	local oplog = seri.unpack(zlib.unzip(len,data))
	local total = #oplog
	local index = 1
	while index < total do
		local nargs = oplog[index]
		handle_command(tunpack(oplog, index+1, index+nargs))
		index = index + nargs + 1
	end
end


local function wsync(...)
	-- 缓存oplog 周期性同步到从节点

	-- 操作数个数
	local nargs = select('#', ...)
	tinsert(OPLOG, nargs)

	-- 操作数
	for n=1, nargs do
		tinsert(OPLOG, (select(n, ...)))
	end
end

local function startup()

	-----------------------------------
	--			客户端
	-----------------------------------

	-- 1. 向从节点同步写操作
	-- 2. 处理客户端请求

	local wop = {
		login=1, reconnect=1, logout=1, 
		set=1, setnx=1, del=1, 
		hset=1, hsetnx=1, hdel=1,
	}

	cluster.dispatch(dictionaryd, function(cli, cmd, ...) 
		if wop[cmd] then 
			wsync(cli.addr, cmd, ...) 
		end
		return handle_command(cli.addr, cmd, ...)
	end)

	cluster.concern('passive.broken', function(addr)
		SLAVE[addr] = nil
		update(addr, false)
		wsync(addr, 'logout')
	end)

	-----------------------------------
	--				主从
	-----------------------------------

	-- 定时同步操作日志到从节点
	lnet.timeout(0.001, math.huge, function()
		if #OPLOG > 0 then
			local buffer, length = seri.pack(OPLOG)
			local data = zlib.zip(buffer, length)
			cluster.multisend(SLAVE, dictinternal, 'lua', 'wsync', length, data)
			OPLOG = {}
		end
		return true
	end)

	-- 主从消息分发
	cluster.dispatch(dictinternal, function(ctx, cmd, ...)
		return ICMD[cmd](ctx.addr, ...) 
	end)

	-- 主节点掉线 立即发起新一轮选举
	cluster.concern('dictionaryd.active.broken', function(v)
		local ok
		while not ok do
			local r = arbitratec.vote('dictionaryd', dictionaryd)
			r.handle = dictinternal
			ok = r.winner or cluster.send(r, 'lua', not v and 'login' or 'reconnect')
		end
	end)

	-- 触发第一次选举
	lnet.call'dictionaryd.active.broken'
end


return {
	startup = startup
}
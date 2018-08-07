local codriver = require 'lnet.codriver'
local timerdriver = require 'lnet.timerdriver'
local sockdriver = require 'lnet.sockdriver'

local os = os
local math = math
local table = table
local type = type
local assert = assert
local error = error
local require = require
local setmetatable = setmetatable


local lnet = {
	genId = codriver.genId,
	fork = codriver.go,
	resume = codriver.go,
	yield = codriver.yield,
	wait = coroutine.yield,
}

function lnet.init(cmd)--{{{
	assert(cmd.type, 'node type is nil')

	-- 设置随机数种子
	math.randomseed(os.time())

	-- 本机环境变量表
	_env = setmetatable(cmd, {__index=require'config'})

	-- 将config中 属于当前节点类型的配置展开到_env
	table.copy(_env, _env[cmd.type] or {})

	-- 生成内网端点
	if not _env.iendpt then
		_env.iaddr  = sockdriver.localhost()
		_env.iport  = assert(_env.iport, 'internal port not set')
		_env.iendpt = _env.iaddr..':'.. _env.iport
	else
		local _,_,iaddr,iport = _env.iendpt:find'(.+):(.+)'
		_env.iaddr = iaddr
		_env.iport = iport
	end

	-- 生成公网端点
	_env.xaddr = _env.iaddr            -- debug
	--_env.xaddr = sockdriver.remotehost() -- release
	if _env.xport then
		_env.xendpt = _env.xaddr..':'.._env.xport
		_env.ixendpt = _env.iaddr..':'.._env.xport
	end

	-- 生成节点名
	_env.node = ('%s@%s_%d'):format(_env.type, _env.iendpt, os.pid())

	--更新控制台显示
	os.console(_env.node)
end--}}}

function lnet.env(key)--{{{
	return key and _env[key] or _env
end--}}}

function lnet.setenv(key, value)
	_env[key] = value
end

function lnet.sleep(ti)--{{{
	timerdriver.new(ti)
end--}}}

function lnet.timeout(ti, rep, f, ...)--{{{
	local session = { valid=true }
	assert(codriver.go(function(...)
		session.env = codriver.genId()
		session.htimer = timerdriver.new(ti, rep+1)
		while lnet.wait() and f(...) do
		end
		session.valid = session.keep
	end, ...))
	return session
end--}}}

function lnet.timeoutx(delay, ti, rep, f, ...)
	local first
	first = lnet.timeout(delay, 1, function(...)
		if f(...) then
			local next = lnet.timeout(ti, rep, f, ...)
			first.keep = true
			first.env = next.env
			first.htimer = next.htimer
		end
	end, ...)
	return first
end

function lnet.cancel(session)--{{{
	assert(session.valid, 'attempt to cancel dead session')
	codriver.go(session.env)
	timerdriver.kill(session.htimer)
	session.valid = false
	session.htimer = nil
end--}}}


local PIPE = {}

local function checkexisting(name)
	if PIPE[name] then
		local errmsg = ('pipe [%s]: has been existed'):format(name)
        error(errmsg, 3)
	end
end

function lnet.pipe(name, callback)
	checkexisting(name)
	callback = callback and callback or name
	assert(type(callback) == 'function')
	assert(type(name)=='string' or type(name)=='function')
	local p = require'pipe.endpoint'(callback)
	local id = p:id()
	PIPE[id]   = p
	PIPE[name] = p
	return id
end

function lnet.xpipe(name)
	checkexisting(name)
	PIPE[name] = require'pipe.multicast'()
	return name
end

function lnet.subscribe(name, callback)
	local id = lnet.pipe(callback)
	PIPE[name]:subscribe(PIPE[id])
end

function lnet.send(dest, ...)
	local p = PIPE[dest]
	return p and p:send(...)
end

function lnet.call(dest, ...)
	local p = PIPE[dest]
	if p then
		return p:call(...)
	end
	return nil, 'can not find pipe'
end


return lnet
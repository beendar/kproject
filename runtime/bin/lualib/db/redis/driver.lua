local lnet = require 'lnet'
local C = require 'database.redis'

local error = error
local assert = assert
local ipairs = ipairs
local tostring = tostring
local setmetatable = setmetatable

local redis = {}
local command = {}
local meta = {
	__index = command
}


local function make_cache(f)
	return setmetatable({}, {
		__mode = "kv",
		__index = f,
	})
end

local header_cache = make_cache(function(t,k)
	local s = "\r\n$" .. k .. "\r\n"
	t[k] = s
	return s
end)

local command_cache = make_cache(function(t,cmd)
	local s = "\r\n$"..#cmd.."\r\n"..cmd
	t[cmd] = s
	return s
end)

local count_cache = make_cache(function(t,k)
	local s = "*" .. k
	t[k] = s
	return s
end)

local function compose_message(cmd, msg)
	local lines = {}
	lines[1] = count_cache[#msg+1]
	lines[2] = command_cache[cmd]
	local idx = 3
	for _,v in ipairs(msg) do
		v= tostring(v)
		lines[idx] = header_cache[#v]
		lines[idx+1] = v
		idx = idx + 2
	end
	lines[idx] = "\r\n"
	return lines
end

local nopending = {
	set = true,
	del = true,
	hset = true,
	hdel = true,
	hmset = true,
	lpush = true,
	rpush = true,
}

local forbidden = {
	subscribe = true,
	psubscribe = true,
	unsubscribe = true,
}

-- crud interface
setmetatable(command , {__index = function(t, cmd)
	if forbidden[cmd] then
		local msg = string.format('redis command [%s]: is forbidden in client mode', cmd)
		error(msg, 2)
	end
	local pending = not nopending[cmd]
	local f = function(self, ...)
		self[1]:commit(compose_message(cmd,{...}))
		return self[1]:wait(pending)
	end
	t[cmd] = f
	return f
end})


function command:concern(callback)
	lnet.subscribe(tostring(self), callback)
end

local function open(self, host)
	return self[1]:open(host)
end

local function auth(self, pass)
	if pass then
		self[1]:commit(compose_message('auth',{pass}), true)
		return (self[1]:wait(true, true))
	end
	return true
end

local function hidecobj(mt)
	-- store c object in a metatable to avoid hotfix conflict
	local hc = {C.new()}
	hc.__index = hc
	setmetatable(hc, mt)
	return hc
end

function redis.open(conf)
	local host = assert(conf[1], 'host is not set')
	local pass = conf.pass
	local self = setmetatable({}, hidecobj(meta))
	lnet.xpipe(tostring(self))
	assert(open(self, host), 'open redis server failed at: ' .. host)
	assert(auth(self, pass), 'auth to redis server failed at: ' .. host)
	self[1]:setopt('keepalive', conf.ti_ping, conf.ti_recv)
	self[1]:panic(function()
		lnet.send(tostring(self), false)
		while not open(self,host) or not auth(self,pass) do
			lnet.sleep(1)
		end
		self[1]:recover()
		lnet.send(tostring(self), true)
	end)
	return self
end


local watch = {}
local watchmeta = {
	__index = watch
}

function redis.watch(conf)
	local host = assert(conf[1], 'host is not set')
	local pass = conf.pass
	local self = setmetatable({ __subscribe={} }, hidecobj(watchmeta))
	assert(open(self, host), 'open redis server failed at: ' .. host)
	assert(auth(self, pass), 'auth to redis server failed at: ' .. host)
	self[1]:panic(function()
		while not open(self,host) or not auth(self,pass) do
			lnet.sleep(1)
		end
		for channel in pairs(self.__subscribe) do
			self:subscribe(channel)
		end
		self[1]:recover()
	end)
	return self
end

local function watchfunc(cmd)
	watch[cmd] = function(self, ...)
		self[1]:commit(compose_message(cmd,{...}))
	end
end

watchfunc'subscribe'
watchfunc'unsubscribe'

function watch:message()
	while true do
		local _,ret = self[1]:wait(true)
		local type, channel, data = ret[1], ret[2], ret[3]
		if type == 'message' then
			return data, channel
		elseif type == 'subscribe' then
			self.__subscribe[channel] = true
		elseif type == 'unsubscribe' then
			self.__subscribe[channel] = nil
		end
	end
end


return redis
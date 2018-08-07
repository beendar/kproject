-- loading protobuf message for compatible with node 
-- that be implemented by other languages
require'pb.parser'.register_str
[[
message cluster
{
	message declare {
		optional string ptype = 1;
		optional string node  = 2;
		optional string type  = 3;
		optional string addr  = 4;
	}
	message question {
		optional int32 question = 1;
		optional string node     = 2;
	}
	message answer {
		optional int32 answer = 1;
	}
	message register {
		optional string type   = 1;
		optional string addr   = 2;
		optional int32 handle = 3;
		optional string extra  = 4;
	}
	message subscribe {
		optional string type   = 1;
		optional string addr   = 2;
	}
	message update {
		message service_t {
			optional string   addr   = 1;
			optional int32    handle = 2;
			optional string   extra  = 3;
		}
		optional string    mode   = 1;
		optional string    type   = 2;
		repeated service_t list   = 3;
	}
}
]]


local sockdriver = require 'lnet.sockdriver'
local lnet  = require 'lnet'
local proto = require 'cluster.public.proto'
local dispatch = require 'cluster.public.dispatch'
local sockmngr  = require 'cluster.public.sockmngr'

local table = table
local next = next

local directoryd = 1
local directoryc = 2

local TYPELOOK  = table.ensure()
local ADDRLOOK  = table.ensure()
local SUBSCRIBE = table.ensure()


function show( ... )
	dump(TYPELOOK)
end

function showsub()
	dump(SUBSCRIBE)
end

function showaddr()
	dump(ADDRLOOK)
end

local function broadcast(readers, handle, ...)
	local p = proto['lua']
	local msg,len = proto.packmsg(p.id, handle, 0, p.pack(...))
	sockdriver.broadcast('q', readers, msg, len)
end

local function publish(type, mode, list)
	broadcast(SUBSCRIBE[type], directoryc,
		'cluster.update', {
			mode = mode, 
			type = type, 
			list = list 
		})
end

local HANDLER = {}

HANDLER['cluster.register'] = function(ctx, msg)
	local addr   = ctx.addr
	local type   = msg.type -- service typename
	local handle = msg.handle
	local extra  = msg.extra
	local name = ('%s:%s'):format(addr, handle)
	local service = { addr=addr, handle=handle, extra=extra }
	TYPELOOK[type][name] = service
	ADDRLOOK[addr][name] = type
	publish(type, 'add', {service})
end

HANDLER['cluster.subscribe'] = function(ctx, msg)
	local addr = ctx.addr
	local type = msg.type
	SUBSCRIBE[type][addr] = ctx:handle()
	return 'cluster.update', {
			mode = 'add',
			type = type,
			list = table.toarray(TYPELOOK[type])
		}
end

HANDLER['cluster.validate'] = function(ctx, type, name)
	local service = TYPELOOK[type][name]
	if service then
		ctx:send('lua', directoryc, 
			'cluster.update', {
				mode = 'add',
				type = type,
				list = {service}
			})
	end
end

HANDLER['cluster.query'] = function(_, msg)
	local type = msg.type
	local mode = msg.mode
	-- random
	if not mode then
		local _,s = next(TYPELOOK[type])
		return s
	end
end

HANDLER['cluster.directory'] = function()
	local dir = {}
	for type,list in pairs(TYPELOOK) do
		dir[type] = table.count(list)
	end
	return dir
end


local function passivebroken(addr)
	for _,readers in pairs(SUBSCRIBE) do
		readers[addr] = nil
	end
	for name,type in pairs(ADDRLOOK[addr]) do
		local service = TYPELOOK[type][name]
		TYPELOOK[type][name] = nil
		publish(type, 'remove', {service})
	end
	ADDRLOOK[addr] = nil
end

local function startup()
	sockmngr.startup()

	dispatch.dispatch(directoryd, function(ctx, cmd, ...)
		return HANDLER[cmd](ctx, ...)
	end)

	lnet.pipe('passive.broken', passivebroken)
end


return {
	startup = startup,
}

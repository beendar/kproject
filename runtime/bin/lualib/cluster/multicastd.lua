local cluster = require 'cluster.slave'

local ipairs = ipairs
local pairs  = pairs
local table  = table

local multicastd = 3
local multicastc = 4

local READER   = table.ensure()
local ADDRLOOK = table.ensure()
function shows()
	dump(READER)
end


local HANDLER = {}

HANDLER['subscribe'] = function(ctx, chan)
	local addr = ctx.addr
	ADDRLOOK[addr][chan] = true
	READER[chan][addr] = addr
end

HANDLER['publish'] = function(_, ...)
	cluster.multisend('multicastd', multicastd, 'lua', '.publish', ...)
end

HANDLER['.publish'] = function(_, chan, ...)
	cluster.multisend(READER[chan], multicastc, 'lua', chan, ...)
end

HANDLER['gather'] = function(_, ...)
	return cluster.multicall('multicastd', multicastd, 'lua', '.gather', ...)
end

HANDLER['.gather'] = function(_, chan, ...)
	return cluster.multicall(READER[chan], multicastc, 'lua', chan, ...)
end


local function startup()

	cluster.concern('passive.broken', function(addr)
		for chan in pairs(ADDRLOOK[addr]) do
			READER[chan][addr] = nil
		end
		ADDRLOOK[addr] = nil
	end)

	cluster.concern('multicastd.online', function(s)
		cluster.touch(s)
	end)

	cluster.subscribe'multicastd'
	cluster.registerx('multicastd', multicastd, function(ctx, cmd, ...) 
		return HANDLER[cmd](ctx,...) 
	end)

end

return {
	startup = startup
}
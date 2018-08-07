local table = table
local cluster = require 'cluster.slave'

local multicastd
local multicastc = 4

local READERS = {}
function showmc()
	dump(READERS)
end


local function subscribe(chan, reader)
	local list = READERS[chan] or {}
	READERS[chan] = list
	if #list == 0 then
		cluster.send(multicastd , 'lua', 'subscribe', chan)
	end
	list[#list+1] = reader
end


local function send(...)
	cluster.send(multicastd, 'lua', 'publish', ...)
end

local function call(...)
	return cluster.call(multicastd, 'lua', 'gather', ...)
end

local function startup()

	cluster.dispatch(multicastc, 
		function(_, chan, ...)
			local feedback = {}
			for _, reader in ipairs(READERS[chan]) do
				table.grab(feedback, reader(...))
			end
			return table.unpack(feedback)
		end)

	cluster.concern('multicastd.offline', 
		function(dropped)
			if multicastd.name == dropped.name then
				multicastd = cluster.wait'multicastd'
				for chan in pairs(READERS) do
					cluster.send(multicastd , 'lua', 'subscribe', chan)
				end
			end
		end)

	multicastd = cluster.wait'multicastd'

end

return {
	startup = startup,
	subscribe = subscribe,
	send = send,
	call = call,
}
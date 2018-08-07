local minheap = require 'minheap'
local cluster = require 'cluster.slave'

local pairs = pairs
local ipairs = ipairs

local empty = {}
local KHEAP = {}
local ADDRKE = table.ensure()

_G.kheap = KHEAP

local CMD = {}

-- 1. 节点启动登录
-- 2. 断线重连(balancerc保留存根)
CMD['new'] = function( addr, key, handle, value, extra )
	local heap = KHEAP[key] or minheap.new()
    KHEAP[key] = heap 
    -- 约定: 
    -- 1. 同一个addr之下 key不重复
    -- 2. value的初始值是0
    local entry = ADDRKE[addr][key]
    if not entry then
   		entry = {
    	    index = 0,
    	    value = value,
    	    data = {
    	        addr = addr,
    	        handle = handle,
    	        extra = extra
			}
		}
		heap:insert(entry)
	else
		entry.value = value
		heap:change(entry)
	end
	ADDRKE[addr][key] = entry
end

CMD['update'] = function( addr, key, value )
    local entry = ADDRKE[addr][key]
    entry.value = value
    KHEAP[key]:change(entry)
end

CMD['query'] = function(_, key)
	local heap = KHEAP[key]
	return heap and heap:min().data or empty
end

CMD['queryn'] = function(_, keys)
	local r = {}
	for idx, key in ipairs(keys) do
		r[idx] = CMD.query(nil, key)
	end
	return r
end

CMD['size'] = function( _, key )
	local heap = KHEAP[key]
	return heap and heap:size() or 0
end

local function startup()
    cluster.concern('passive.broken', function(addr)
        for key, entry in pairs(ADDRKE[addr]) do
            KHEAP[key]:remove(entry)
        end
        ADDRKE[addr] = nil
	end)

	cluster.registerx('balancerd', function(ctx, cmd, ...) 
		return CMD[cmd](ctx.addr, ...) 
	end)
end


return {
	startup = startup
}
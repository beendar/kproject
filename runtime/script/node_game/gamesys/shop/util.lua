local util = require 'gamesys.util'
local malldata = require 'metadata'.mall

local os = os
local math = math

local function randfunc(seed)--{{{
	local mul = seed
	return function(l, h)
		l = l or 0
		h = h or 0x7fffffff
		mul = mul * 0xefff % 0x7fffffff
		return l + mul % (h-l+1)
	end
end--}}}

local function genrandlist(id, seed)
    local conf = malldata[id]
    
    local pool = conf.goodsID
    local count = conf.minGoods
    local random = seed and randfunc(seed) or math.random

    local list = {}

    while count > 0 do
        local tid = util.bsearch(pool.list, random(1,pool.total)).tid
        if not list[tid] then
            list[tid] = tid
            count = count - 1
        end
    end

    return list
end

local function gennextrefresh(id)
    local conf = malldata[id]
    return os.time() + conf.refreshcycle*3600
end


return {
    genrandlist = genrandlist,
    gennextrefresh = gennextrefresh,
}
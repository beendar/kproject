local ceil = math.ceil
local random = math.random
local util = require 'gamesys.util'

local metadata = require 'metadata'
local itemdata = metadata.item
local roledata = metadata.character
local cardpool = metadata.extract

local shared = {
    [1] = {}
}


local function binarysearchx(list, g)
    local lo = 1
    local hi = #list
    while lo < hi do
        local mi = ceil((lo+hi)*0.5)
        local mv = list[mi].g
        if g == mv then
            return list[mi].tid
        elseif mi-lo == 1 then
            if g <= list[lo].g then
                return list[lo].tid
            end
            if g > list[lo].g and g <= mv then
                return list[mi].tid
            end
            return list[hi].tid
        elseif g < mv then
            hi = mi
        elseif g > mv then
            lo = mi
        end
    end
    return list[lo].tid
end

local function check(model, n)
	local tid = 30005
    local conf = itemdata[tid] -- 固定消耗的物品
    shared[1].tid = tid
    shared[1].count = n*conf.p1
    model.bag:removeitem(shared)
end

local function extractcard(model, n)
    local lookup = model.archive.role
    local role = {}
    local item = {}
    local roleidlist = {}

    for i=1, n do
        local id = random(1, #cardpool)
        local g  = random(1, cardpool[id].total)
        local roleid = binarysearchx(cardpool[id].list, g) -- 必定抽中
        roleidlist[#roleidlist+1] = roleid  

        if lookup[roleid] then
            local fragid  = roledata[roleid].starUp[1][1].tid
            local fragcnt = roledata[roleid].fragment
            local entry = item[fragid] or { tid=fragid, count=0 }
            item[fragid] = entry
            entry.count = entry.count + fragcnt
        else
            local one = util.newrole(model.pid, model.rgnid, roleid)
            role[#role+1] = one
            model.role[roleid] = one
        end
    end

    model.bag:additem(item)

    return {
        role = role,
        item = item,
        roleidlist = roleidlist,
    }
end

return {
    check = check,
    card = extractcard,
}

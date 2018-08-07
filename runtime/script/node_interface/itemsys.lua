local metadata = require 'metadata'
local itemdata = metadata.item
local stonedata = metadata.itemstone



local itemsys = {}

function itemsys.typename(tid)
    if tid == 40002 then return 'energy' end
    if itemdata[tid] then return 'item' end
    if stonedata[tid] then return 'stone' end
end

function itemsys.detail(tid)
    local itemconf = itemdata[tid]
    local stoneconf = stonedata[tid]

    if tid == 40002 then
        return { type='energy', name='体力' }
    elseif itemconf then
        return { type='item', name=string.format('物品 - %s', itemconf.name) }
    elseif stoneconf then
        return { type='stone', name=string.format('魂石 - %s', stoneconf.forceName) }
    end

    asserti(nil, '无效的物品ID!')
end


return itemsys
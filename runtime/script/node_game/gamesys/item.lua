local util = require 'gamesys.util'
local metadata = require 'metadata'

local math = math
local table = table
local assert = assert
local errorf = errorf
local errorfa = errorfa
local ipairs = ipairs
local pairs = pairs

local idrange  = metadata.idrange
local itemdata = metadata.item
local chestdata = metadata.chestdrop
local stonecommondata = metadata.stoneCommon[1]

local TYPE_ROLE_EXP = 7
local TYPE_ROLE_FAVOUR = 2
local TYPE_ROLE_RARE = 3
local TYPE_ROLE_AWAKE = 4
local TYPE_STONE_EXP = 5
local TYPE_STONE_RARE = 6
local TYPE_CHIP = 10
local TYPE_CHEST = 12

local TYPE_ENERGY = 101
local TYPE_CHARACTER_EXP = 102
local TYPE_PLAYER_EXP = 103


local function typestone(tid)
	return (tid >= idrange[1].min and tid <= idrange[1].max)
end

local function idtotype(tid)
    local v = itemdata[tid]
    errorfa(v, 'item id %d do not exsit', tid)
    return v.type
end

local function calcsum(list)
    local sum = 0
    for _, item in pairs(list) do
        local conf = itemdata[item.tid]
        sum = sum + item.count*conf.p1 --简单参量默认配置于p1字段
    end
    return sum
end

local function calcroleexp(roleid, list)
    local total = 0
	for _,item in pairs(list) do
		local conf = itemdata[item.tid]
		if conf.type == TYPE_ROLE_EXP then
			total = total + conf.p1*item.count
		elseif conf.type == TYPE_ROLE_FAVOUR then
			total = total + ((roleid==conf.p2) and (conf.p3*item.count) or (conf.p1*item.count))
		end
	end
	return total		
end


local itemsys = {}

local handler = {}

handler[TYPE_ROLE_EXP] = function(model, req)
    local total = calcroleexp(req.role, req.items)
	local role = model.role[req.role]
	role:addlevelexp(total)
end

handler[TYPE_ROLE_FAVOUR] = function(model, req)
    local total = calcroleexp(req.role, req.items)
	local role = model.role[req.role]
	role:addfavourexp(total)
	return { skill=role.skill }
end

handler[TYPE_ROLE_RARE] = function(model, req)
	local role = model.role[req.role]
    role.quality = role.quality + 1
end

handler[TYPE_ROLE_AWAKE] = function(model, req)
	local role = model.role[req.role]
    role.awake = 1
end

handler[TYPE_STONE_EXP] = function(model, req)
    local total = calcsum(req.items)
	local stone = model.stone[req.stone]
    local usedexp = stone:addlevelexp(total)
    local goldcost = usedexp*stonecommondata.perExpGold 
    if goldcost > 0 then
        model.bag:addcoin('gold', -goldcost)
    end
end

handler[TYPE_STONE_RARE] = function(model, req)
	local stone = model.stone[req.stone]
    local curstar = stone:upgrade()
    local goldcost = stonecommondata.starUPGold[curstar]
    model.bag:addcoin('gold', -goldcost)
end

handler[TYPE_CHIP] = function(model, req)
    local pid = model.pid
    local rgnid = model.rgnid

    local chip = req.items[1]
    local conf = itemdata[chip.tid]
	assert(conf.p1 > 0, 'consume count is zero')

    local tid = conf.p2
    local count = math.floor(chip.count / conf.p1) -- 持有数量 / 配置消耗

    local r = {}

    if typestone(tid) then
        r.stone = {}
        for n=1, count do
            table.insert(r.stone, util.newstone(pid, rgnid, tid, model:gensn()))
        end
    else
        r.item = { util.newitem(tid, count) }
    end
  
    return r
end

handler[TYPE_CHEST] = function(model, req)
    local pid = model.pid
    local rgnid = model.rgnid

    -- 各种检查
    local chest = req.items[1]
    local conf = chestdata[itemdata[chest.tid].p1]

    local r = {}

    for n=1, chest.count do
        local v = util.bsearch(conf.list, math.random(conf.total))
        local tid = v.tid
        local count = v.count

        if typestone(tid) then
            r.stone = r.stone or {}
            table.insert(r.stone, util.newstone(pid, rgnid, tid, model:gensn()))
        else
            r.item = r.item or {}
            if not r.item[tid] then
                r.item[tid] = util.newitem(tid, 0)
            end
            r.item[tid].count = r.item[tid].count + count
        end
    end

    return r
end

handler[TYPE_ENERGY] = function(model, req)
	local incre = calcsum(req.items)
	return { energy=model.base:addenergy(incre) }
end

handler[TYPE_PLAYER_EXP] = function(model, req)
    local total = calcsum('player', req.items)
	model.base:addplayerexp(total)
end


function itemsys.use(model, req)
    local type = idtotype(req.items[1].tid)

    local r = handler[type](model, req)
    if r then
        itemsys.apply(r, model)
    end
    return r
end

function itemsys.gen(list, model, ret)
    ret = ret or {}

    local items = {}
    for _,v in pairs(ret.item or {}) do
        items[v.tid] = v.count
    end

    for _,v in pairs(list or {}) do
        local type = idtotype(v.tid)
        if typestone(v.tid) then
            if not ret.stone then
                ret.stone = {}
            end
            table.insert( ret.stone, util.newstone(model.pid, model.rgnid, tid, model:gensn()))
        elseif type == TYPE_ENERGY then
            ret.energy = (ret.energy or 0) + v.count
        elseif type == TYPE_PLAYER_EXP then
            ret.player_exp = (ret.player_exp or 0) + v.count
        elseif type == TYPE_CHARACTER_EXP then
            ret.character_exp = (ret.character_exp or 0) + v.count
        elseif type <= 100 then
            items[v.tid] = (items[v.tid] or 0) + v.count
        else
            errorf('itemtype %d is not valid', type)
        end
    end

    local ritems = {}
    for tid, count in pairs(items) do
        table.insert( ritems,util.newitem(tid, count) )
    end

    ret.item = #ritems > 0 and ritems

    return ret
end

function itemsys.apply(list, model, ...)
    local bag = model.bag
    bag:addstone(list.stone or {})
    bag:additem(list.item or {})

    local chars = ...
    if list.character_exp then
        assert(chars)
        for _, tid in pairs(chars) do
            local role = model.role[tid]
            role:addlevelexp(list.character_exp)
        end
    end
    
    if list.player_exp then
        model.base:addplayerexp(list.player_exp)
    end
    return list
end

return itemsys
local table = table
local error = error
local assert = assert
local ipairs = ipairs
local pairs = pairs
local time = os.time
local ceil = math.ceil

local metadata = require 'metadata'
local constant = metadata.constant
local itemdata = metadata.item
local stonedata = metadata.itemstone
local idrange  = metadata.idrange
local roledata = metadata.character
local committal = metadata.committal

local PMETHOD_DUNGEON = constant.PMETHOD_DUNGEON
local PMETHOD_FOGMAZE = constant.PMETHOD_FOGMAZE


-- 新建角色
local function newrole(pid, rgnid, tid)
	return {
		pid   = pid,
		rgnid = rgnid,
		tid    = tid,
		level  = 1,
		level_exp = 0,
		awake = 0,
		awake_exp = 0,
		quality = roledata[tid].quality,
		quality_exp = 0,
		favour = 1,
		favour_exp = 0,
		wisman = 0,
		sanctuary = {0,0,0,0,0,0,0,0,0,0},
		stone  = {0,0,0}, -- 三种形状的魂石孔
		skill  = {	{ level=1}, {level=1}, {level=1} },
	} 
end

-- 新建机器人角色
local function newbot(tid, level, awake, quality, skill_level)
	local skill = {
		level = skill_level
	}

	return {
		tid = tid,
		level = level,
		awake = awake,
		quality = quality,
		skill = { skill, skill, skill },
	}
end

-- 新建魂石
local function newstone(pid, rgnid, tid, sn)
	return {
		pid   = pid,
		rgnid = rgnid,
		tid   = tid,
		sn    = sn,
		level = 1,
		exp   = 0,
		star  = stonedata[tid].starBegin,
		rela  = 0,
	}
end

-- 新建委托
local function newcommittal(pid, rgnid, tid, sn)
	return {
		pid = pid,
		rgnid = rgnid,
		sn = sn,
		tid = tid,
		status = 0,
		times = committal[tid].times,
		expire = os.time() + difftime(0, 0, 0),
	}
end

-- 新建道具
local function newitem(tid, count)
	return { tid=tid, count=count }
end

local pmethodfilter = {}

pmethodfilter[PMETHOD_DUNGEON] = function(pid, rgnid)
	return {
		pid = pid,
		rgnid = rgnid,
		methodid = PMETHOD_DUNGEON,

		reset = time(),
		unfinished = {},
		touched = {},
	}
end

pmethodfilter[PMETHOD_FOGMAZE] = function(pid, rgnid)
	return {
		pid = pid,
		rgnid = rgnid,
		methodid = PMETHOD_FOGMAZE,
		maxstage = 1, -- 默认解锁第1关

		--energy = mazedata[stage].energy,
		--stage = stage,
		--map = map,
		--level = 1,
		--x = 65536,
		--y = 65536,
		box = nil,
		--boxLevel = {},
		--team = team,
	}
end

-- 新建玩法
local function newpmethod(pid, rgnid, methodid, ...)
	return pmethodfilter[methodid](pid, rgnid, ...)
end

-- 新建章节
local function newchapter(pid, rgnid, dungeonid, chapterid, stageid)
	return {
		pid = pid,
		rgnid = rgnid,
        dungeonid = dungeonid, -- 副本类型id (对应pvedungeon.xlxs主键)
		tid = chapterid,	   -- 章节id
		level = {stageid,0,0}, -- 三个难度当前可挑战的关卡id 0未解锁 0xDEAD该难度clear
		action_1 = {0,0,0,0,0}, -- 三个难度小节统计信息
		action_2 = {0,0,0,0,0},
		action_3 = {0,0,0,0,0},
	}
end

-- 获取物品id类型名
local function idtypename(itemid)
	for idx,entry in pairs(idrange) do
		if itemid >= entry.min and itemid <= entry.max then
            return entry.name
		end
	end
    error('can not find typename of item id '..itemid, 2)
end

local function check_committal( tid )
	return committal[tid] ~= nil
end

local function bsearch(list, g)
    local lo = 1
    local hi = #list
    while lo < hi do
        local mi = ceil((lo+hi)*0.5)
        local mv = list[mi].g
        if g == mv then
            return list[mi]
        elseif mi-lo == 1 then
            if g <= list[lo].g then
                return list[lo]
            end
            if g > list[lo].g and g <= mv then
                return list[mi]
            end
            return list[hi]
        elseif g < mv then
            hi = mi
        elseif g > mv then
            lo = mi
        end
    end
    return list[lo]
end



return {

	newrole    = newrole,
	newstone   = newstone,
    newitem    = newitem,
    newpmethod = newpmethod,
	newchapter = newchapter,
	newcommittal = newcommittal,

    idtypename = idtypename,
	check_committal = check_committal,
	bsearch = bsearch,

	newbot = newbot,
}
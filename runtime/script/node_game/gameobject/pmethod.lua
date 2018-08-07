local bit = require 'bit' --TODO: LUA VERSION
local time = os.time
local math = math
local ipairs = ipairs
local assert = assert
local difftime = difftime
local setmetatable = setmetatable

---@type constant
local metadata = require 'metadata'
local constant= metadata.constant
local stagedata = metadata.pvestage
local mazedata = metadata.maze
local mazemapdata = metadata.mazemap

local PMETHOD_DUNGEON = constant.PMETHOD_DUNGEON
local PMETHOD_FOGMAZE = constant.PMETHOD_FOGMAZE

local TOLERANCE = 10

---@class pmethod
---@field _data tPMethod
local dungeon_interface = {}

-- 副本玩法支持的操作
-- 因为有多种处理不统一的副本 所以可能需要多态

---------------------------------------
--      dungeon
---------------------------------------

function dungeon_interface:tryreset()
    local now = time() + TOLERANCE
    if now >= self.reset then
        self.touched = {}
        self.reset = now + difftime(0,0,0)
        return true
    end
end

function dungeon_interface:update_touched(stageid)
    local one = self.touched[stageid]
    if not one then
        one = { tid=stageid, used=1, bought=0, }
        self.touched[stageid] = one
    else
        one.used = one.used + 1
    end
end

function dungeon_interface:avaliable(stageid)
    local one = self.touched[stageid]
    if not one then return true end
    local conf = stagedata[stageid]
    return one.used < conf.cntLimt
end

function dungeon_interface:update_unfinished(firsttime, stageid, star)
    -- lo16 stageid
    -- hi16 history star, using binary bits

    -- has been got 3 stars in earlier time
    local oldval = self.unfinished[stageid]
    if not firsttime and not oldval then
        return 0
    end

    local increbits = star

    if oldval then
        local laststar = math.floor(oldval/constant.STARSHIFT)
        increbits = bit.band(star, bit.bxor(laststar,constant.STARMAX))
        star = bit.bor(star, laststar)
    end

    if star < constant.STARMAX then
        self.unfinished[stageid] = stageid + star*constant.STARSHIFT
    else
        self.unfinished[stageid] = nil
    end

    return increbits
end

function dungeon_interface:update_formation(formation)
    self.formation = table.clone(formation)
end

---------------------------------------
--      fog maze
---------------------------------------

local boxlvawardname = {
    'bronze_award',
    'silver_award',
    'gold_award',
    'diamond_award'
}

local function boxdropid(mapid, boxlv)
    local field = boxlvawardname[boxlv] 
    local list = mazemapdata[mapid][field]
    return list[math.random(#list)]
end

local function packboxitem(mapid, boxlv)
    return boxlv*65536 + mapid
end

local function unpackboxitem(n)
    local mapid = n % 65536
    local boxlv = math.floor(n / 65536)
    return mapid, boxlv
end

local fogmaze_interface = {}

function fogmaze_interface:update(id, box, boxlv, x, y, map, won, boss, monster)
    local EVENT_BOX = 1
    local EVENT_BATTLE_BEGIN = 2
    local EVENT_BATTLE_END = 3
    local EVENT_NEXTLV = 4
    local EVENT_SUSPEND = 5

    if EVENT_BOX == id then
        self.box = box
        self.boxLevel[#self.boxLevel+1] = packboxitem(self.map, boxlv)
        self.x = x
        self.y = y

    elseif EVENT_BATTLE_END == id then
        local left = self.energy - (won and 1 or 3)
        assert(left >= 0, 'energy is used out')
        self.x = x
        self.y = y
        self.energy = left
        self.monster = monster
        if boss > 0 then self.boss[boss] = boss end
    elseif EVENT_NEXTLV == id then
        self.x = x
        self.y = y
        self.map = map
        self.level = self.level + 1
        self.box = 0
        self.monster = 0
        self.boss = {}
    elseif EVENT_SUSPEND == id then
        self.x = x
        self.y = y
    end
end

function fogmaze_interface:boxesdropid(perfect)
    local r = {}
    for i,n in ipairs(self.boxLevel) do
        r[i] = boxdropid(unpackboxitem(n))
    end
    r[#r+1] = perfect and mazedata[self.stage].win_award or nil
    return r
end

function fogmaze_interface:update_formation(formation)
    self.team = table.clone(formation)
end

function fogmaze_interface:begin(stage, map)
    self.energy = mazedata[stage].energy
    self.stage = stage
    self.map = map
    self.level = 1
    self.x = 65536
    self.y = 65536
    self.box = 0
    self.boxLevel = {}
    self.boss = {}
    self.monster = 0
end

function fogmaze_interface:finish(perfect)
    local nextstage = self.maxstage + 1
    -- 尝试解锁下一关
    if perfect
        and mazedata[nextstage]
        and self.stage == self.maxstage 
    then
        self.maxstage = nextstage
    end
    -- 当前挑战关复位
    self.stage = 0
end


return {
    select = function(data)
        local id = assert(data.methodid)
        return (id==PMETHOD_DUNGEON) and dungeon_interface or fogmaze_interface
    end

}
local bit = require 'bit' -- TODO: LUA VERSION

local math = math
local assert = assert
local setmetatable = setmetatable

---@type constant
local metadata = require 'metadata'
local constant = metadata.constant
local actioninfo = metadata.actioninfo
local actiondata = metadata.pveaction
local awardsdata = metadata.awards

local function getaction(self, diffculty)
    if diffculty == constant.DIFFCULTY_NORMAL then
        return self.action_1
    elseif diffculty == constant.DIFFCULTY_HARD then
        return self.action_2
    elseif diffculty == constant.DIFFCULTY_MAX then
        return self.action_3
    end
end

local function getactionawardsconf(actionid, diffculty)
    local ad = actiondata[actionid]
    if diffculty == constant.DIFFCULTY_NORMAL then
        return ad.levelAwards1
    elseif diffculty == constant.DIFFCULTY_HARD then
        return ad.levelAwards2
    elseif diffculty == constant.DIFFCULTY_MAX then
        return ad.levelAwards3
    end
end

---@class chapter
local interface = {}

function interface:avaliable(diffculty, stageid)
    local sofar= self.level[diffculty]
    return (sofar > 0 and stageid <= sofar)
end

function interface:firsttime(diffculty, stageid)
    return self.level[diffculty] == stageid
end

function interface:updatelevel(diffculty, nextstageid)
    self.level[diffculty] = nextstageid
end

function interface:addstar(diffculty, idx, increbits)
    local incre = 0
    incre = incre + bit.band(increbits, 1)
    incre = incre + bit.rshift(bit.band(increbits,2), 1)
    incre = incre + bit.rshift(bit.band(increbits,4), 2)
    local action = getaction(self, diffculty)
    action[idx] = action[idx] + incre*constant.STARSHIFT
end

function interface:applyactionaward(actionid, diffculty, awardindex)
    local ai = actioninfo[actionid]

    local action = getaction(self, diffculty)
    local value = action[ai.index]

    -- 检查对应档的奖励是否领取过
    local mask = math.pow(2, awardindex-1)
    assert(bit.band(value, mask) == 0, 'action award of this index has been retrieved')

    -- 检查要求的星数是否满足
    local conf = getactionawardsconf(actionid, diffculty)
    local index = (awardindex-1)*2 + 1
    local stars = math.floor(value / constant.STARSHIFT)
    assert(stars >= conf[index], 'stars is not enough')

    -- 更新领取记录
    action[ai.index] = bit.bor(value, mask)

    -- 奖励进包
    local awardid = conf[index+1]
    local awards = awardsdata[awardid].dropList

    self.Model.bag:additem(table.clone(awards))
end


return interface
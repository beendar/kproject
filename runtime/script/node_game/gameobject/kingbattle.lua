local util = require 'gamesys.util'

local setmetatable = setmetatable
local diffwdaytime = diffwdaytime

local os = os
local bit = bit
local math = math
local table = table
local assert = assert

local kbcmdata = require 'metadata'.kingbattlecommon[1]

local minscore = 1000
local tolerance = 10
local won_shift = 65536

local interface = {}


function interface:update_score(inc)
    local old = self.score
    local cur = old + inc
    cur = math.max(minscore, cur)
    self.score = cur
    return old, cur
end

function interface:update_formation(type, formation)
    if type == 1 then
        self.formation_atk = table.clone(formation)
    end
    if type == 2 or not self.formation_def then
        self.formation_def = table.clone(formation)
    end
end

function interface:is_refresh_timeout()
    local ti = self.refresh_ti
    return (os.time()+tolerance >= ti)
end

function interface:update_refresh_timeout()
    local ti = self.refresh_ti
    if ti == -1 then
        self.refresh_ti = 0
    else
        self.refresh_ti = os.time() + kbcmdata.refresh_time
    end
end

function interface:applystagereward(stage)
    assert(stage==1 or stage==2, 'invalid stage number')

    local won_count = math.floor(self.won / won_shift)
    local got_mask = self.won % 65536

    local need_count = stage == 1 and 3 or 5
    assert(won_count >= need_count, 'won count is not enough')

    local mask = math.pow(2, stage - 1)
    assert(bit.band(got_mask,mask) == 0, 'has been got reward of this stage')

    -- 更新领取标记
    self.won = self.won + mask

    -- 应用奖励
    local r = {}
    local reward = kbcmdata['stage_reward_'..stage]

    for idx=1, #reward, 2 do
        local tid = reward[idx]
        local count = reward[idx+1]
        self.Model.bag:incitem(tid, count)
        table.insert(r, util.newitem(tid,count))
    end

    return r
end


return interface
local bit = require 'bit' -- TODO: LUA VERSION
local util  = require 'gamesys.util'
local drop  = require 'gamesys.drop'

local ipairs = ipairs
local assert = assert

---@type constant
local metadata     = require 'metadata'
local constant     = metadata.constant
local chapterdata  = metadata.pvechapter
local actiondata   = metadata.pveaction
local stagedata    = metadata.pvestage
local stageinfo    = metadata.stageinfo
local missiondata  = metadata.mission
local awardsdata   = metadata.awards

local PMETHOD_DUNGEON  = constant.PMETHOD_DUNGEON
local DIFFCULTY_NORMAL = constant.DIFFCULTY_NORMAL
local DIFFCULTY_MAX    = constant.DIFFCULTY_MAX
local DIFFCULTY_CLEAR  = constant.DIFFCULTY_CLEAR
local DIFFCULTY_NAME   = { 'levels_1', 'levels_2', 'levels_3' }


local function getfirststage(chapterid, diffculty)
    local name = DIFFCULTY_NAME[diffculty]
    local actionid = chapterdata[chapterid].actions[1]
    local action = actiondata[actionid]
    return action[name][1]
end

local function getnextstage(si)
    local nextstageid = si.nextstageid
    if nextstageid then
        return nextstageid
    end
    local nextactionid = si.nextactionid
    if nextactionid then
        local name = DIFFCULTY_NAME[si.diffculty]
        return actiondata[nextactionid][name][1]
    end
    return DIFFCULTY_CLEAR
end

local function getstaraward(stageid, index)
    local sd = stagedata[stageid]
    local missionid
    if index == 1 then
        missionid = sd.mission1
    elseif index == 2 then
        missionid = sd.mission2
    else
        missionid = sd.mission3
    end
    local awardid = missiondata[missionid].reward
    return awardsdata[awardid].dropList[1].count
end

local function checkcond(model, stageid)
    -- 体力够不够
    model.base:energyup()
    model.base:energydown(stagedata[stageid].energyCost)

    -- 是否已经解锁
    local si = assert(stageinfo[stageid], 'invalid stageid')
    local chapter = model.chapter[si.chapterid]
    assert(chapter, 'chapter has not been unlocked yet')
    assert(chapter:avaliable(si.diffculty, stageid), 'stage is unavaliable')

    -- 挑战次数够不够（先重置 再检测)
    local pmethod = model.pmethod[PMETHOD_DUNGEON]
    pmethod:tryreset()
    assert(pmethod:avaliable(stageid), 'avaliable challenge count has been used out')
end

local function update(model, stageid, star, won, team)
    local si = stageinfo[stageid]

    ---@type pmethod
    local pmethod = model.pmethod[PMETHOD_DUNGEON]

    ---@type chapter
    local chapter = model.chapter[si.chapterid]

    -- 是否初次挑战本关
    local firsttime = chapter:firsttime(si.diffculty, stageid)

    -- [玩法]相关的更新
        -- 挑战记录
    pmethod:update_touched(stageid)

        -- 星数增量(二进制位)
    local increbits = pmethod:update_unfinished(firsttime, stageid, star)

    -- [章节]相关的更新
        --小节统计信息
    chapter:addstar(si.diffculty, si.actionindex, increbits)

        -- 关卡解锁
    local nextstageid
    local nextdiffcultystageid
    local nextchapter

    if firsttime and won then
        nextstageid = getnextstage(si)
        chapter:updatelevel(si.diffculty, nextstageid)
    end

    if nextstageid == DIFFCULTY_CLEAR then
        --  1. 解锁本章 下一个难度 1-1 如果有
        local nextdiffculty= si.diffculty + 1
        if nextdiffculty <= DIFFCULTY_MAX then
            nextdiffcultystageid = getfirststage(si.chapterid, nextdiffculty)
            chapter:updatelevel(nextdiffculty, nextdiffcultystageid)
        end
        --  2. 解锁下一章 普通难度 1-1 如果有(当且仅当上一章normal难度首次clear)
        local nextchapterid= si.nextchapterid
        if nextchapterid and si.diffculty == DIFFCULTY_NORMAL then
            local nextchapterstageid = getfirststage(nextchapterid, DIFFCULTY_NORMAL)
            nextchapter = util.newchapter(model.pid, model.rgnid, si.dungeonid, nextchapterid, nextchapterstageid)
            model.chapter[nextchapterid] = nextchapter
        end
    end

    -- 掉落及升级
    local item
    local stone

    if won then
        local sd = stagedata[stageid]
        local bag = model.bag
        -- 掉落
        item, stone = drop.dungeon(model, stageid, firsttime)
        bag:additem(item)
        bag:addstone(stone)
        -- 加金币
        bag:addcoin('gold', sd.Coin)
        -- 任务奖励
        if increbits > 0 then
            local rmb = 0
            if bit.band(increbits, 1) > 0 then rmb = rmb + getstaraward(stageid, 1) end
            if bit.band(increbits, 2) > 0 then rmb = rmb + getstaraward(stageid, 2) end
            if bit.band(increbits, 4) > 0 then rmb = rmb + getstaraward(stageid, 3) end
            bag:addcoin('rmb', rmb)
        end
        -- 加玩家经验
        model.base:addplayerexp(sd.accountEXP)
        -- 角色升级
        for _,tid in ipairs(team) do
            local role = model.role[tid]
            role:addlevelexp(sd.EXP)
        end
    end

    return {
        cur_diffculty_nextstageid = nextstageid,
        next_diffculty_firststageid = nextdiffcultystageid,
        next_chapter = nextchapter,
        item = item,
        stone = stone,
    }
end


--!@brief: open all chapter for debugging
local function openall(pid, rgnid)
    -- remove all old chapter data
    local col = require 'lnet'.env'db':getcol'chapter'
    col:remove{
        pid = pid, 
        rgnid = rgnid
    }

    -- insert new chapter data
    local list = {} 
    for idx, chapterid in ipairs(metadata.pvedungeon[1].chapters) do
        local chapter = util.newchapter(pid, rgnid, 1, chapterid)
        chapter.level = {
            DIFFCULTY_CLEAR,
            DIFFCULTY_CLEAR,
            DIFFCULTY_CLEAR
        }
        table.insert(list, chapter)
    end

    col:batch_insert(list)
    col:concern()
    print'done'
end


return {
    checkcond = checkcond,
    update = update,
    openall = openall,
}
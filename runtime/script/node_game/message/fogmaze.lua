local util = require 'gamesys.util'
local drop = require 'gamesys.drop'

local table = table

local mazedata = require 'metadata'.maze


local HANDLER = {}

HANDLER['MazeGameBegin'] = function(u, req)
    local stage = req.stage
    local map = req.map

    local md = mazedata[stage]
    local base = u.model.base

    -- 检查玩家等级
    assert(base.plv >= md.levelneed, 'player level is not enough')

    -- 检查体力
    base:energyup()
    base:energydown(md.tilineed)

    -- 检查钥匙

    -- 2 PMETHOD_FOGMAZE
    local pm = u.model.pmethod[2]
    pm:begin(stage, map)
end

HANDLER['MazeGameEvent'] = function(u, req)
    local id = req.method
    local box = req.box
    local boxlv = req.boxLevel
    local x = req.x
    local y = req.y
    local map = req.map
    local won = req.won
    local boss = req.boss
    local monster = req.monster

    -- 2 PMETHOD_FOGMAZE
    local pm = u.model.pmethod[2]
    pm:update(id, box, boxlv, x, y, map, won, boss, monster)
end

HANDLER['MazeGameEnd'] = function(u, req)
    local model = u.model
    local pm = model.pmethod[2]
    local item,stone = drop.fogmaze(model, pm:boxesdropid(req.perfect))
    model.bag:additem(item)
    model.bag:addstone(stone)
    pm:finish(req.perfect)
    return { item=item, stone=stone }
end


return HANDLER
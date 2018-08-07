local kbsys = require 'gamesys.kingbattle'
local kbranksys = require 'gamesys.kingbattlerank'


local HANDLER = {}

HANDLER['KingBattleContext'] = function(u, req)
    -- 获取完整的玩法上下文（若可以重置则先重置)
    if req.type == 0 then
        return { ctx=kbsys.reset(u.model) }
    else
    -- 获取部分字段
        return {
            score = u.model.kingbattle.score
        }
    end
end

HANDLER['KingBattleSetFormation'] = function(u, req)
    u.model.kingbattle:update_formation(req.type, req.formation)
end

HANDLER['KingBattleSearch'] = function(u, req)
    local refresh_ti, result = kbsys.search(u.model)
    return {
        refresh_ti = refresh_ti,
        enemies = result
    }
end

HANDLER['KingBattleGetFormation'] = function(u, req)
    local rolelist, stonelist = kbsys.getformation(u.model, req.indexofenemy)
    return {
        role = rolelist,
        stone = stonelist,
    }
end

HANDLER['KingBattleBegin'] = function(u)
    kbsys.beginbattle(u.model)
end

HANDLER['KingBattleEnd'] = function(u, req)
    return kbsys.endbattle(u.model, req.won)
end

HANDLER['KingBattleAward'] = function(u, req)
    return {
        item = u.model.kingbattle:applystagereward(req.stage)
    }
end

HANDLER['KingBattleRank'] = function(u, req)
    local list, your_rank = 
        kbranksys.getpage(u.pid, u.rgnid, u.model.kingbattle.score, req.page)

    return {
        list = list,
        your_rank = your_rank
    }
end

HANDLER['KingBattleVideo'] = function(u, req)
end


return HANDLER
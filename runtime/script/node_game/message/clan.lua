local clansys = require 'gamesys.clan'
local chatsys = require 'gamesys.chat'


local HANDLER = {}

HANDLER['ClanCreate'] = function(u, req)
    local name = req.name
    local sign = req.sign
    local icon = req.icon
    local opcode = clansys.create(u.model, name, sign, icon)
    return { opcode=opcode }
end

HANDLER['ClanLogin'] = function(u)
    return { 
        clanbase = clansys.login(u.model) 
    }
end

HANDLER['ClanRetrieveMember'] = function(u, req)
    local clanid = req.clanid
    local page = req.page
    return {
        page = page,
        clanid = clanid,
        member = clansys.loadmember(clanid, u.rgnid, page)
    }
end

HANDLER['ClanRequestJoin'] = function(u, req)
    return {
        ok = clansys.requestjoin(u.model, req.clanid)
    }
end

HANDLER['ClanHandleJoin'] = function(u, req)
    clansys.handlejoin(u.model, req.target, req.ok)
end

HANDLER['.ClanHandleJoin'] = function(u, clanid)
    u.model.base.clanid = clanid
    u.agent:send('ClanHandleJoin', {clanid=clanid})
end

HANDLER['ClanQuit'] = function(u)
    clansys.quit(u.model)
    chatsys.drop(2, u.model)
end

HANDLER['ClanKick'] = function(u, req)
    clansys.kick(u.model, req.target)
end

HANDLER['.ClanKick'] = function(u)
    u.model.base.clanid = nil
    u.agent:send('ClanKick', {})
    chatsys.drop(2, u.model)
end

HANDLER['ClanSearch'] = function(u, req)
    -- 根据id精确搜索
    if req.type == 1 then
        return { clanbase = {clansys.searchbyid(req.variant)} }
    end
    -- 根据公会名模糊匹配
    return { clanbase = clansys.searchbyname(req.variant) }
end

HANDLER['ClanRetrieveHistoryEvent'] = function(u, req)
    return {
        history = clansys.retrievehistoryevent(u.model, req.type)
    }
end

HANDLER['ClanSetRole'] = function(u, req)
    return {
        ok = clansys.setrole(u.model, req.target, req.role)
    }
end

HANDLER['ClanModifyBaseInfo'] = function(u, req)
    return {
        opcode = clansys.modifybaseinfo(u.model, req.field, req.value)
    }
end

HANDLER['ClanUpgrade'] = function(u, req)
    return {
        ok = clansys.upgrade(u.model)
    }
end

HANDLER['ClanDeleteMessage'] = function(u, req)
end


return HANDLER
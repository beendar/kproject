local actioninfo = require 'metadata'.actioninfo
local dungeonsys = require 'gamesys.dungeon'


local HANDLER = {}

HANDLER['PveBattleBegin'] = function(u, req)
end

HANDLER['PveBattleEnd'] = function(u, req)
	dungeonsys.checkcond(u.model, req.stageid)
	return dungeonsys.update(u.model, req.stageid, req.star, req.won, req.team)
end

HANDLER['BattleArray'] = function(u, req)
	local pmid = req.type == 1 and 1 or 2
	u.model.pmethod[pmid]:update_formation(req.array)
end

HANDLER['PveActionAward'] = function(u, req)
	local actionid = req.actionid
	local diffculty = req.diffculty
	local awardindex = req.awardindex
	assert(awardindex>=1 and awardindex<=3, 'invalid award index')

	local chapterid = actioninfo[actionid].chapterid
	local chapter = u.model.chapter[chapterid]
	chapter:applyactionaward(actionid, diffculty, awardindex)
end


return HANDLER
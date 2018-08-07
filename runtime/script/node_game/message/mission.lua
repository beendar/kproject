local util = require 'gamesys.util'

local assert = assert


local HANDLER = {}

HANDLER['MissionRefresh'] = function( u, req )
    local m = u.model.mission
    m:refresh()
	return m
end

HANDLER['MissionUpdate'] = function( u, req )
    local m = u.model.mission
    m:update(req.mission)
end

HANDLER['MissionReward'] = function( u, req )
    local m = u.model.mission
    return {
        ok = m:reward(req)
    }
end

return HANDLER
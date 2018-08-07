local util = require 'gamesys.util'
local island = require'gamesys.island'
local assert = assert


local HANDLER = {}

HANDLER['IslandData'] = function( u, req )
    return u.model.island
end

HANDLER['IslandUpgrade'] = function( u, req )
    local base = u.model.island
    return {
        device = base:upgrade(req.tid)
    }
end

HANDLER['IslandEvent'] = function( u, req )
    -- body
end

HANDLER['IslandUseDevice'] = function( u, req )
    local base = u.model.island
    local device = base:find(req.tid)
    assert(device, 'device is not found')
    return {
        device = island.use(device, req.ext)
    }
end

HANDLER['IslandGetReward'] = function( u, req )
    local base = u.model.island
    local device = base:find(req.tid)
    assert(device, 'device is not found')
    return {
        device = island.getreward(device)
    }
end

return HANDLER
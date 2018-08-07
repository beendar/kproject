local util = require 'gamesys.util'

local assert = assert


local HANDLER = {}

HANDLER['GuideEnd'] = function(u, req)
    u.model.base.guide_id = req.gid
    return {
        ok = true
    }
end

return HANDLER
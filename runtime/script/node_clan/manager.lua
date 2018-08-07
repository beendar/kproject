local util = require 'util'

local CMD = {}

CMD['create'] = function(...)
    local clanid = util.newclan(...)
    return clanid
end

CMD['load'] = function(clanid)
    local clanpos, winner = util.loadclan(clanid)
    return clanpos
end


return {
    launch = function()
        return 'clan.manager', function(_, cmd, ...)
            return CMD[cmd](...)
        end
    end
}
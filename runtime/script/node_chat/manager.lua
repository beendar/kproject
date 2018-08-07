local codecache = require 'codecache'
local location  = require 'pub.location'

local table = table
local ipairs = ipairs

local REGION = {}
local PUBCHAT = {}


local CMD = {}

function CMD.pub(u)
    -- search a proper room instance of public chating
    local inst
    for _,pc in ipairs(PUBCHAT) do
        if not pc.full() then
            inst = pc
            break
        end
    end
    -- there isn't proper one, create new
    if not inst then
        inst = codecache.call'roompub'
        table.insert(PUBCHAT, 1, inst)
    end
    -- return to remote caller
    return inst.join(u)
end

function CMD.clan(clanid)
    local inst = codecache.call'roomclan'
    local ok, pos = location.setnx('clanroom', clanid, inst.addr, inst.handle)
    if not ok then
        inst:stop()
    end
    return pos
end


return {
    launch = function()
        return 'chat.manager', function(_, cmd, ...)
            return CMD[cmd](...)
        end
    end
}
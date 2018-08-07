local ipairs = ipairs
local error = error
local assert = assert
local random = math.random
local util = require'gamesys.util'

local metadata        = require 'metadata'
local stagedata       = metadata.pvestage
local normaldroptable = metadata.itemdrop
local firstdroptable  = metadata.itemfirstdrop

local MAXCHANCE = 10000

local function dropquantity(entry)
    if random(1, MAXCHANCE) > entry.chance then
        return 0
    end
    return random(entry.min, entry.max)
end


---@param u user
local function drop(model, dropid, droptable, outitem, outstone)
    local conf = droptable[dropid]
    if not conf then
        local errmsg = ('config do not exist of this drop id - %d'):format(dropid)
        error(errmsg)
    end

    for _,entry in ipairs(conf.drop) do
        local tid = entry.tid
        local dq = dropquantity(entry)

        if dq > 0 then
            if util.idtypename(tid) ~= 'Stone' then
                local one = outitem[tid]
                if not one then
                    one = util.newitem(tid, 0)
                    outitem[tid] = one
                end
                one.count = one.count + dq
            else
                for n=1, dq do
                    outstone[#outstone+1] = util.newstone(model.pid, model.rgnid, tid, model:gensn())
                end
            end
        end
    end

    return outitem, outstone
end


local function dungeon(model, stageid, firsttime)
    local sd        = stagedata[stageid]
    local dropid    = firsttime and sd.first or sd.drops
    local droptable = firsttime and firstdroptable or normaldroptable
    return drop(model, dropid, droptable, {}, {})
end

local function fogmaze(model, boxesdropid)
    local outitem = {}
    local outstone = {}
    for _, dropid in ipairs(boxesdropid) do
        drop(model, dropid, normaldroptable, outitem, outstone)
    end
    return outitem, outstone
end


return {
    dungeon = dungeon,
    fogmaze = fogmaze,
}
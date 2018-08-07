local cluster = require 'cluster.slave'
local location = require 'pub.location'

local assert = assert

local PUB  = 1
local CLAN = 2

local NAMEPUB  = 'chatroom.pub'
local NAMECLAN = 'chatroom.clan'

local NAMELOOK = {
    [PUB] = NAMEPUB,
    [CLAN] = NAMECLAN,
}

local function on_drop(model, room)
    cluster.send(room, 'lua', 'drop', model.pid)
end

local JOIN = {}

JOIN[PUB] = function(model)
	local room = model:getvar(NAMEPUB)
    if room then return room end
    local mngr = cluster.query'chat.manager'
	room = cluster.call(mngr, 'lua', 'pub', model.base:summary'chat')
	model:setvar(NAMEPUB, room, on_drop)
	return room
end

JOIN[CLAN] = function(model)
    local base = model.base

    -- has not been join a clan
    local clanid = assert(base.clanid, 'you have not joined a clan yet')

    -- has been join a clan chat room
    local room = model:getvar(NAMECLAN)
    if room then return room end

    -- otherwise, try finding room instance where is
    room = location.get('clanroom', clanid, true)

    -- chat room of this clan do no exist, tell chat manager to create one
    if not room then
        local mngr = cluster.query'chat.manager'
        room = cluster.call(mngr, 'lua', 'clan', clanid)
    end

    -- join chat room
    room = cluster.call(room, 'lua', 'join', base:summary'chat')

    -- remeber chat room instance
    model:setvar(NAMECLAN, room, on_drop)

    return room
end


local function join(channel, model)
    local f = assert(JOIN[channel], 'invalid channel id')
    return f(model)
end

local function drop(channel, model)
    local name = assert(NAMELOOK[channel], 'invalid channel id')
    model:delvar(name)
end

-- only public chat room support "switch" method
local function switch(model)
    local room = assert(model:getvar(NAMEPUB), 'has not been join a public chat room yet')
    -- switch to next room
    room = cluster.call(room, 'lua', 'switch', model.pid)
    model:setvar(NAMEPUB, room, on_drop)
    return room
end


return {
    join = join,
    drop = drop,
    switch = switch,
}
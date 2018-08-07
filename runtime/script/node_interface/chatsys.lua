local cluster = require 'cluster.slave'
local multicastc = require 'cluster.multicastc'
local location = require 'pub.location'


local CMD = {}

CMD['global'] = function(req)
    local pid = asserti(req.pid, 'pid not set')
    local name = asserti(req.name, 'display name not set')
    local content = asserti(req.content, 'content not set')
    multicastc.send('chat.global', pid, name, content, req.extra)
end

CMD['ban'] = function(req)
    local pid = asserti(req.pid, 'pid not set')
    local duration = asserti(req.duration, 'duration not set')
    local pos = location.get('user', pid)
    cluster.send(pos, 'lua', '.banchat', duration)
end


local chatsys = {}

function chatsys.handle(req) 
    local f = asserti(CMD[req.optype], 'invalid optype')
    return f(req)
end


return chatsys
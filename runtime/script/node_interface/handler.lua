local HANDLER = {}

HANDLER['/ping'] = function(data)
    return 'pong'
end
HANDLER['/opmail'] = function(data)
	return require'mailsys'.handle(data)
end

HANDLER['/opchat'] = function(data)
    return require'chatsys'.handle(data)
end

HANDLER['/cluster/dir'] = function()
    local cluster = require 'cluster.slave'
    local directoryd = cluster.query'directoryd'
    return cluster.call(directoryd, 'lua', 'cluster.directory')
end

HANDLER['/itemdetail'] = function(data)
    return require'itemsys'.detail(data.tid)
end


return HANDLER
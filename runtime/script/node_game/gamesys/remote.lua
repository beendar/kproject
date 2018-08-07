env = env or {

    lnet = require 'lnet',
    cluster = require 'cluster.slave',

    mongo = require'lnet'.env'db',
    redis = require'lnet'.env'redis.game',

    gate = require 'module.gate',
    online = require 'module.online',

    location = require 'pub.location',
    metadata = require 'metadata',
    mailsys = require 'gamesys.mail',
    mailsender = require 'gamesys.mailsender',
    archive = require 'gamesys.archive',
    drop = require 'gamesys.drop',
    extract = require 'gamesys.extract'
}

-- shortcut 
env.tclone = table.clone
env.tcopy = table.copy

env.kick = function(pid)
    env.online.kick(pid)
end

env.find = function(pid)
    return env.online.get(pid)
end

env.locate = function(pid)
    return env.location.get('user', pid)
end

setmetatable(env, {__index=_G})

local function launch()
    return 'game.remote', function(_, str)
        local f,errmsg = loadstring(str)
        if not f then
            return false, errmsg
        end
        setfenv(f, env)
        return pcall(f)
    end
end


return {
    launch = launch
}
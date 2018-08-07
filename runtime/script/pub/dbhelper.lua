local dbopen = require 'pub.dbopen'

local handler = {}

handler['game'] = function()
    local db = dbopen.mongo'game':getdb'kgame'
    for _, name in pairs {
        'bag', 'base', 'chapter', 'clanbase',
        'clanmember', 'committal', 'friend',
        'jungle', 'kagutsu', 'mallrecord',
        'mission', 'pmethod', 'role', 'stone',
    } 
    do
        db:getcol(name):drop()
        db:getcol(name):ensureindex('pid', 'rgnid')
    end
    db:getcol'base':listindex()
    print'mongo.game has been reset'
end

handler['mail'] = function()
    local db = dbopen.mongo'mail':getdb'kgame'
    db:getcol'sysmail':drop()
    db:getcol'usermail':drop()
    db:getcol'usermail':ensureindex('pid', 'rgnid')
    db:getcol'usermail':ensureindex('pid', 'rgnid', 'id')
    db:getcol'usermail':listindex()
    print'mongo.mail has been reset'
end

handler['account'] = function()
    local db = dbopen.redis'game'
    db:del'geniduser'
    db:del'genidclan'
    db:del'account'
    db:del'hnickname:user'
    db:del'hnickname:clan'
    assert(db:keys'*')
    print'redis.game has been reset'
end

local function reset(name)
    local f = handler[name]
    f()
end


return {
    reset = reset
}
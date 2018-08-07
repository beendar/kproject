local lnet = require 'lnet'
local openmongo = require 'db.mgo.driver'
local openredis = require 'db.redis.driver'.open


local function ensureconf(type, name)
    local key = ('conf.%s.%s'):format(type, name)
    local conf = lnet.env(key)
    if not conf then
        local errmsg = ('invalid %s config name: %s'):format(type, name)
        error(errmsg, 3)
    end
    return conf
end

local function redis(name)
    local conf = ensureconf('redis', name)
    return openredis(conf)
end

local function mongo(name)
    local conf = ensureconf('mongo', name)
    return openmongo(conf)
end


return {
    redis = redis,
    mongo = mongo,
}
local lnet = require 'lnet'
local cluster = require 'cluster.slave'
local arbitratec = require 'cluster.arbitratec'

local dictionaryd

local function set(key, value)
    cluster.send(dictionaryd, 'lua', 'set', key, value)
end

local function setnx(key, value)
    return cluster.call(dictionaryd, 'lua', 'setnx', key, value)
end

local function get(key)
    return cluster.call(dictionaryd, 'lua', 'get', key)
end

local function del(key)
    cluster.send(dictionaryd, 'lua', 'del', key)
end

local function hset(key, field, value)
    cluster.send(dictionaryd, 'lua', 'hset', key, field, value)
end

local function hsetnx(key, field, value)
    return cluster.call(dictionaryd, 'lua', 'hsetnx', key, field, value)
end

local function hget(key, field)
    return cluster.call(dictionaryd, 'lua', 'hget', key, field)
end

local function hdel(key, field)
    cluster.send(dictionaryd, 'lua', 'hdel', key, field)
end

local function startup()

    cluster.concern('dictionaryd.active.broken', function(v)
        dictionaryd = arbitratec.result'dictionaryd'
        cluster.send(dictionaryd, 'lua', not v and 'login' or 'reconnect')
    end)

    lnet.call'dictionaryd.active.broken'
end


return {
    startup = startup,
    set = set,
    setnx = setnx,
    get = get,
    del = del,
    hset = hset,
    hsetnx = hsetnx,
    hget = hget,
    hdel = hdel,
}
local redis
local seri = require 'lnet.seri'
local cast = require 'extend.cast'
local genid = require 'pub.genid'

local assert = assert
local tostring = tostring

local shift = 1200000
local keyname = 'account'

local activation_key = 'activation_code'

-- utility
local function unpack(data)
    return seri.unpack(data)
end

local function pack(t)
    local buffer, len = seri.pack(t)
    return cast.ptoa(buffer, len)
end


-- module function
local function generate(token, pwd)
    local acct = {
        token = token,
        pid = genid.next'user',
        pwd = pwd
    }
    local _, ok = redis:hsetnx(keyname, token, pack(acct))
	assert(ok == 1, 'conflict with same token when creating new account')
    return acct
end

local function get(token, strict)
    local _, acct = redis:hget(keyname, token)
    return acct and unpack(acct) or (not strict and generate(token))
end

local function update(token, acct)
    redis:hset(keyname, token, pack(acct))
end

local function exist( token, password )
    local _, acct = redis:hget(keyname, token)
    if acct then
        acct = unpack(acct)
        if acct.pwd == password then
            return acct
        end
    end
end

local function startup(obj)
    redis = obj
    genid.startup(obj)
end


return {
    startup = startup,
    get = get,
    update = update,
    generate = generate,
    gen_acode = generate_activation_code,
    exist = exist
}
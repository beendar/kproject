local seri = require 'protocol.seri'
local encrypt = require 'protocol.encrypt'

local assert = assert
local strpackx = string.packx
local strunpackx = string.unpackx

local rheader = 'HI'
local wheader = 'HIp'


local function pack(name, data)
    local id, msg, len = seri.pack(name, data, 'C')
    return strpackx(wheader, id, 0, msg, len)
end

local function unpack(msg, len, secret)
    local id,sign,msg,len = strunpackx(rheader, msg, len)
    local name, data = seri.unpack(id, msg, len, 'S')
    local ok = encrypt.validate(sign, data[secret], msg, len)
    assert(ok, 'malformed signature')
    return name, data
end


return {
    pack = pack,
    unpack = unpack,
}
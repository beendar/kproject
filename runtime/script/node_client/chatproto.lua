local seri = require 'protocol.seri'
local encrypt = require 'protocol.encrypt'

local strpackx = string.packx
local strunpackx = string.unpackx

local rheader = 'HI'
local wheader = 'HIp'


local function pack(name, data, secret)
    local id, msg, len = seri.pack(name, data, 'S')
    local sign = encrypt.sign(secret, msg, len)
    return strpackx(wheader, id, sign, msg, len)
end

local function unpack(msg, len)
    local id, _, msg, len = strunpackx(rheader, msg, len)
    return seri.unpack(id, msg, len, 'C')
end


return {
    pack = pack,
    unpack = unpack,
}
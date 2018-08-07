local lnet = require 'lnet'
local proto = require 'chatproto'
local sockdriver = require 'lnet.sockdriver'

local pcall  = pcall
local setmetatable = setmetatable

local iaddr  = lnet.env'iaddr'
local xaddr  = lnet.env'xaddr'


local mt = {}
mt.__index = mt
mt.__call = function()
    local fd = sockdriver.udp(iaddr..':0')
    local _, port = sockdriver.name(fd, true)
    return setmetatable({
        _fd = fd,
        _ctx = {},
        _list = {},
        _iendpt = ('%s:%d'):format(iaddr, port), -- for forking sub-socket
        xendpt  = ('%s:%d'):format(xaddr, port), -- publish to clients
    }, mt)
end

function mt:check()
    return sockdriver.check(self._fd)
end

function mt:loop(dispatch)
    for msg,len,addr,port in sockdriver.recvfrom, self._fd do
        local ok,cmd,req = pcall(proto.unpack, msg, len, 'secret') -- 密钥含于'secret'字段
        if ok then
            ok,cmd = pcall(dispatch, cmd, req, addr, port)
        end
        if not ok then print(cmd) end
    end
end

--------------------------------------
--   style 1
--------------------------------------

function mt:update(uid, addr, port)
    self._list[uid] = sockdriver.endpoint(addr, port) 
end

function mt:drop(uid)
    self._list[uid] = nil
end

function mt:broadcast(id, t)
    local msg, len = proto.pack(id, t)
    sockdriver.broadcast('s', self._list, msg, len, self._fd)
end

function mt:close()
    sockdriver.close(self._fd)
end


return setmetatable(mt, mt)
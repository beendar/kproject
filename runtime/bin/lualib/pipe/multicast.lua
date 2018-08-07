local log     = require 'log'
local kwait   = require 'coroutine'.yield
local ksend   = require 'lnet.codriver'.send
local genId   = require 'lnet.codriver'.genId
local fork    = require 'lnet.codriver'.go
local lpack   = require 'lnet.seri'.pack


local mt = {}
mt.__index = mt


function mt:send(...)
    ksend(0, self._id, lpack(...))
end

function mt:subscribe(p)
    table.insert(self._subscriber, p)
end

return function()
    local subscriber = {}
    local function dispatch(msg, len)
        for _,p in ipairs(subscriber) do
            p:sendraw(msg, len)
        end
    end
    local id
    fork(function()
        id = genId()
        for _,msg,len in kwait do
            local ok,errmsg = fork(dispatch, msg, len)
            if not ok then log.error(errmsg) end
        end
    end)
    return setmetatable({
        _id = id,
        _subscriber = subscriber,
    }, mt)
end
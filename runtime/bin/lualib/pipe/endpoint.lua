local log     = require 'log'
local kwait   = require 'coroutine'.yield
local ksend   = require 'lnet.codriver'.send
local genId   = require 'lnet.codriver'.genId
local fork    = require 'lnet.codriver'.go
local lpack   = require 'lnet.seri'.pack
local lunpack = require 'lnet.seri'.unpack


local mt = {}
mt.__index = mt


function mt:id()
    return self._id
end

function mt:sendraw(msg, len)
    ksend(0, self._id, msg, len)
end

function mt:send(...)
    self:sendraw(lpack(...))
end

function mt:call(...)
    local ok,errmsg = ksend(genId(), self._id, lpack(...))
	if ok then
		return lunpack(select(2,kwait()))
	end
	return nil, errmsg
end


return function(callback)
    local function dispatch(source, msg, len)
        local r,l = lpack(callback(lunpack(msg,len)))
        if source > 0 then
            ksend(0, source, r, l)
        end
    end
    local id
    fork(function()
        id = genId()
        for source,msg,len in kwait do
            local ok,errmsg = fork(dispatch, source, msg, len)
            if not ok then log.error(errmsg) end
        end
    end)
    return setmetatable({
        _id = id
    }, mt)
end
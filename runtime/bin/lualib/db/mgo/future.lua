local lnet   = require 'lnet'
local genId  = lnet.genId
local fork   = lnet.fork
local wait   = lnet.wait
local resume = lnet.resume
local assert = assert


local mt = {}
mt.__index = mt


function mt:gensn()
	local sn = self._sn + 1
	self._sn = sn
	return sn
end

function mt:addpending()
	local pending = self._pending + 1
	self._pending = pending
end

function mt:load(colname, cond, selector)
	local id = genId()
	local sn = self:gensn()
    assert(fork(function()
		local r = self._proxy:load(colname, cond, selector)
		resume(id, sn, r)
	end))
	self:addpending()
end

function mt:wait()
	while self._pending > 0 do
		local sn, r = wait()
		self._result[sn] = r
		self._pending = self._pending - 1
	end
	local index = self._index + 1
	self._index = index
	return self._result[index]
end


return function(proxy)
	return setmetatable({
		_sn = 0,
		_index = 0,
		_pending = 0,
		_result = {},
        _proxy = proxy,
	}, mt)
end

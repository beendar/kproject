local tremove = table.remove
local tinsert = table.insert
local setmetatable = setmetatable


local pnamemt = {}
local function setpname(pname, msg)
	local mt = pnamemt[pname] 
	if not mt then
		mt = { PN = pname }
		mt.__index = mt
		pnamemt[pname] = mt
	end
	return setmetatable(msg, mt)
end

local mt = {}
mt.__index = mt
mt.__call = function(_, maxpending)
    return setmetatable({
		_box = {}, 
		_maxpending = maxpending
	}, mt)
end

function mt:count()
    return #self._box
end

function mt:full()
	return (#self._box >= self._maxpending)
end

function mt:push(pname, msg)
	if not self:full() then
		tinsert(self._box, setpname(pname,msg))
	end
end

function mt:pop()
    local msg = tremove(self._box, 1)
    return msg.PN, msg
end


return setmetatable(mt, mt)
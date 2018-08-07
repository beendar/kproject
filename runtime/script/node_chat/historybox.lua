local tremove = table.remove
local tinsert = table.insert
local setmetatable = setmetatable


local mt = {}
mt.__index = mt
mt.__call = function(_, maxhistory)
    return setmetatable({
        _box = {},
        _maxhistory = maxhistory
    }, mt)
end

function mt:full()
    return (#self._box >= self._maxhistory)
end

function mt:push(msg)
    if self:full() then
        tremove(self._box, 1)
    end
    tinsert(self._box, msg)
end

function mt:getall()
    return self._box
end

function mt:getbytime(time)
    local list = {}
    for i=#self._box, 1, -1 do
        local msg = self._box[i]
        if msg.time > time then
            tinsert(list, msg)
        else
            break
        end
    end
    return list
end


return setmetatable(mt, mt)
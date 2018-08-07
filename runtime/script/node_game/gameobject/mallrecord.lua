local math = math
local setmetatable = setmetatable



local SHIFT = 65536

local function pack(tid, count)
    return count*SHIFT + tid
end

local function unpack(packed)
    local tid = packed % SHIFT
    local count = math.floor(packed / SHIFT)
    return tid, count
end


local interface = {}

function interface:get(id)
    if not self[id] then
        self[id] = {
            bought = {},    -- 购买记录 key: goodsid, val: pack(tid, count)
            refresh_ti = 0, -- 刷新超时(由商店实例生成)
        }
        self.__data:save() -- 确保无副作用
    end
    return self[id]
end

function interface:getfield(id, field)
    local record = self:get(id)
    return record[field]
end

function interface:tryrefresh(id, refresh_ti)
    local record = self:get(id)
    if record.refresh_ti < refresh_ti then
        record.bought = {}
        record.refresh_ti = refresh_ti
    end
end

--!@param id  商店id
--!@param tid 商品id
function interface:updatestock(id, tid)
    local bought = self:get(id).bought
    local value = bought[tid] or pack(tid, 0)
    bought[tid] = value + SHIFT
end

function interface:checkstock(id, tid, stock)
    -- 结合已购记录 
    -- 对于当前用户 tid标识的商品是否还有"库存"
    local bought = self:get(id).bought

    local value = bought[tid]
    if not value then
        return true
    end

    local _, count = unpack(value)
    return (count < stock)
end


return interface
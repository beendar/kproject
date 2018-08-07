local factory = require 'gameobject.factory'

local pairs = pairs


local mloader = {}

--!@brief: 将id对应的实例数据封装为gameobject
function mloader:__index(id)
    local obj = self.__cache[id]
    if obj then
        return obj
    end

    local data = self.__collection[id]
    if data then
        local obj = factory.construct(self.__colname, data, self.__model)
        self.__cache[id] = obj
        return obj
    end
end

--!@breif: 将新增的实例插入集合
function mloader:__newindex(id, value)
    self.__collection[id] = value
    if not value then
        self.__cache[id] = nil
    end
end

--!@brief: 遍历集合
function mloader:__pairs()
    return pairs(self.__collection)
end

--!@brief: 不触发同步的情况下 增加键值对
local function rawset(self, id, value)
    self.__collection:rawset(id, value)
end

--!@brief: 不触发gameobject构建的情况下 获取gameobject的数据
local function rawget(self, id)
    return self.__collection._raw[id]
end


return {
    load = function(colname, model)
        return setmetatable({
            __colname = colname,
            __collection = model.archive[colname],
            __model = model,
            __cache = {},
            rawset = rawset,
            rawget = rawget,
        }, mloader)
    end
}
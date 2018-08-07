local pairs = pairs
local require = require
local setmetatable = setmetatable


local object = {}

function object:__index(key)
    return self.__data[key] or self.__interface[key]
end

function object:__newindex(key, value)
    self.__data[key] = value
end

function object:__pairs()
    return pairs(self.__data)
end


local path_cache = setmetatable({}, { 
    __index = function( cache, colname )
        local path = 'gameobject.' .. colname
        cache[colname] = path
        return path 
    end
})

local function load(colname, data)
    local interface = require(path_cache[colname])
    if not interface.select then
        return interface
    end
    return interface.select(data)
end


return {
    construct = function(colname, data, model)
        return setmetatable({
            Model = model, -- 'Model' and 'Pure' are reserved fieldname
            Pure = data._raw,
            __data = data,
            __interface = load(colname, data)
        }, object)
    end
}
local conf = require'metadata'.island

local islandsys = {}
local use = {
    --校门
    [1] = function( device, ext )
        return device
    end,
    --广场
    [2] = function( device, ext )
        return device
    end,
    --食堂
    [3] = function( device, ext )
        return device
    end,
    --教学楼
    [4] = function( device, ext )
        if device.action == 0 then
            for _, char in ipairs(ext) do
                local role = self.Model.role[char]
                assert(role,'role is not found')
                role:addmask(2)
            end
            device.ext = ext
            device.action = 2
            device.expire = os.time() + 30
        end
        return device
    end,
    --图书馆
    [5] = function( device, ext )
        return device
    end,
    --操场
    [6] = function( device, ext )
        return device
    end,
    --时针塔
    [7] = function( device, ext )
        return device
    end,
    --小卖部
    [8] = function( device, ext )
        return device
    end,
    --神社
    [9] = function( device, ext )
        return device
    end,
}


local reward = {
    --校门
    [1] = function( device )
        return device
    end,
    --广场
    [2] = function( device )
        return device
    end,
    --食堂
    [3] = function( device )
        return device
    end,
    --教学楼
    [4] = function( device )
        if device.action == 2 then
            for _, char in ipairs(device.ext or {}) do
                local role = self.Model.role[char]
                assert(role,'role is not found')
                role:removemask(2)
            end
            device.ext = ext
            device.action = 0
            device.expire = 0
        end
        return device
    end,
    --图书馆
    [5] = function( device )
        return device
    end,
    --操场
    [6] = function( device )
        return device
    end,
    --时针塔
    [7] = function( device )
        return device
    end,
    --小卖部
    [8] = function( device )
        return device
    end,
    --神社
    [9] = function( device )
        return device
    end,
}

function islandsys.use( device, ext )
    return use[device.tid](device, ext)
end

function islandsys.getreward( device )
    return reward[device.tid](device)
    -- if device.action == 0 and device.expire <= os.time() then
    --     -- 无需使用的产出类或特殊类的设施
    -- elseif device.action == 2 and device.expire <= os.time() then
    --     -- 可以使用的设施
    --     device.action = 0
    --     for _, char in pairs(device.ext) do
    --         local role = self.Model.role[char]
    --         assert(role,'role is not found')
    --         role:removemask(2)
    --     end
    --     device.ext = nil
    --     device.expire = 0
    -- end
end


return islandsys
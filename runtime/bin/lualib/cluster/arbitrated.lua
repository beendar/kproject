local cluster = require 'cluster.slave'

local os = os
local table = table

local VOTING = {} 
local RESULT = {}

local CMD = {}

CMD['vote'] = function(addr, key, handle, turn, duration)
    -- 如果可以 直接返回上一次的选举结果
    local r = RESULT[key]
    if r then
        return r
    end

    -- 受理本次选举
    local v = VOTING[key] or {
            turn = turn,
            expire = os.time() + duration
        }
    
    VOTING[key] = v

    -- 处理一轮选举过程种 新启动节点乱入的情况
    if v.turn < turn then
        v.turn = turn
        v.expire = v.expire + duration
    end

    -- 先到先得 初次触发这个条件的成功胜出
    if v.turn == turn and os.time() > v.expire then

        -- 记录选举结果
        RESULT[key] = {
            turn = turn + 1,
            addr = addr, 
            handle = handle,
        }

        -- 反向映射胜出者地址与选举键
        RESULT[addr] = key

        -- 结束本轮选举
        VOTING[key] = nil

        -- 胜出者立即获得结果
        local r = table.clone(RESULT[key])
        r.winner = true

        return r
    end
end

CMD['maintain'] = function(addr, key, r)
    -- 不论如何 只要遭遇断开 胜者应主动要求延续自己的地位
    r.winner = nil

    RESULT[key] = r
    RESULT[addr] = key

    -- 因为胜者归来 如果在此之前已发起了选举 则这场选举立即终止 
    VOTING[key] = nil
end

CMD['result'] = function(_, key)
    return RESULT[key]
end

local function startup()

    cluster.concern('passive.broken', function(addr)
        local key = RESULT[addr]
        if key then
            RESULT[key] = nil
            RESULT[addr] = nil
        end
    end)

    cluster.registerx('arbitrated', function(ctx, cmd, ...)
        return CMD[cmd](ctx.addr, ...)
    end)

end

return {
    startup = startup
}
--[[
    message GlobalEvent {
        optional int32 type = 1;
        optional int32 time = 2;
        optional string content = 3; (encode in json format)
    }
    message ClanEvent {
        optional int32 type = 1;
        optional int32 time = 2;
        optional string content = 3; (be encoded in json format)
    }
--]]


--!@brief: 借助chat集群传播事件到确定范围的客户端
local cjson = require 'extend.cjson'
local cluster = require 'cluster.slave'
local multicastc = require 'cluster.multicastc'
local location = require 'pub.location'

local os = os
local type = type
local error = error
local assert = assert


local CMD = {}

CMD['global'] = function(event)
    -- 投递到所有公共聊天室
    -- 继而发给所有在线客户端
    multicastc.send('chat.global', event)
end

CMD['clan'] = function(event, clanid, persist)
    -- 借助公会聊天室传播公会事件
    local pos = location.get('clanroom', clanid)
    cluster.send(pos, 'lua', '.ClanEvent', event, persist)
end

local function raise(top, _type, content, ...)
    -- 检查顶层类型
    local f = CMD[top]
    if not f then
        local errmsg = ('invalid event top type - %s'):format(top)
        error(errmsg, 2)
    end
    -- 检查事件类型及内容
    assert(type(_type) == 'number',   'event type must be a number')
    assert(type(content) == 'table', 'event content must be a table')
    -- 创建事件
    local event = {
        type = _type,
        time = os.time(),
        content = cjson.encode(content) -- 统一为json编码
    }
    -- 分发处理
    return f(event, ...)
end


return {
    raise = raise
}
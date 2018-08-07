local cjson = require 'extend.cjson'
local codecache = require 'codecache'

local os = os

local maxpending = 100
local maxhistory = 200

local base = codecache.call('roombase', maxpending, maxhistory)

--C2S 公会成员发言 包装为type=0的公会事件
base.addhandler('ChatSaying', function(u, req)
    -- 心跳包
    if #req.content == 0 then return end
    -- 压入发送队列 并做内存级持久化
	base.push('ClanEvent', {
        type = 0, -- text chat
        time = os.time(),
        content = cjson.encode{ pid=u.pid, content=req.content },
    }, true)
end)

--S2S 其他node抛送的公会事件
base.addhandler('.ClanEvent', function(msg, persist)
    -- 压入发送队列
    base.push('ClanEvent', msg, persist)
end)

--S2S 其他node要求获取公会历史事件
-- type = 0 全量
-- type = 1 增量
base.addhandler('.RetrieveHistoryEvent', function(type, time)
    return base.gethistory(type, time)
end)

        
return base
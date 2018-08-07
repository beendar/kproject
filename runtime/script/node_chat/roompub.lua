local multicastc = require'cluster.multicastc'
local codecache = require 'codecache'

local os = os

local maxpending = 100
local maxhistory = 0

local base = codecache.call('roombase', maxpending, maxhistory)

-- 用户公共频道聊天消息
base.addhandler('ChatSaying', function(u, req)
    -- 心跳包
    if #req.content == 0 then return end
    -- 压入发送队列
	base.push('ChatSaying', {
        pid = u.pid,
        nickname = u.nickname,
        headid = u.headid,
        plv = u.plv,
        content = req.content,
        time = os.time(),
    })
end)

multicastc.subscribe(
	'chat.global', function(msg)
		base.push('GlobalEvent', msg)
	end)
        
return base
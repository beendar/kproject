local lnet = require 'lnet'
local cluster = require 'cluster.slave'

local os = os
local table = table
local assert = assert

local maxpending, maxhistory = ...
local maxuser = 100
local userctx = {}
local usercnt = 0
local ssobj = require 'sockservice'()
local inbox = require 'inbox'(maxpending)
local hibox = require 'historybox'(maxhistory)


local inst = {
	addr = lnet.env'iendpt',  -- cluster service address
	handle = cluster.gensid(),
}

function inst.join(u)
	local pid = u.pid
	if not userctx[pid] then
		userctx[pid] = u
		usercnt = usercnt + 1
	end
	local secret = os.time()
	userctx[pid].secret = secret
	return {
		-- for client
		pid = pid, 
		secret = secret,		
		host = ssobj.xendpt,
        -- for cluster
		addr   = inst.addr,
		handle = inst.handle,
	}
end

function inst.drop(pid)
	local u = userctx[pid]
	if u then 
		userctx[pid] = nil
		usercnt = usercnt - 1 
	end
	ssobj:drop(pid)
end

function inst.push(pname, msg, persist)
	-- 压入发送队列
	inbox:push(pname, msg)
	-- 尝试压入历史队列
	if persist then
		hibox:push(msg)
	end
end

function inst.start()
	
	-- client message loop
    assert(lnet.fork(function()
		ssobj:loop(function(cmd, req, addr, port)
			local pid = req.pid
            local u = userctx[pid]
            if u and u.secret == req.secret then
                inst[cmd](u, req)
				ssobj:update(pid, addr, port)
			end
        end)
    end))

	-- sending loop
    assert(lnet.fork(function()
        while ssobj:check() do
			if inbox:count() > 0 then 
				ssobj:broadcast(inbox:pop())
			else
				lnet.sleep(0.001)
			end
        end
	end))

	-- cluster request dispatch
	cluster.dispatch(inst.handle, function(_, cmd, ...)
		return inst[cmd](...)
    end)
    
    return inst
end

function inst.stop()
    ssobj:close()
end

function inst.full()
	return (usercnt >= maxuser)
end

function inst.addhandler(name, func)
	assert(not inst[name], name)
	inst[name] = func
end

-- type 0 全量
-- type 1 增量
function inst.gethistory(type, time)
	if type == 0 then
		return hibox:getall()
	end
	return hibox:getbytime(time)
end

return inst.start()

local pid, rgnid, secret,
	model, agent, addr, handle  = ...


local inst = {
	pid    = pid,
	rgnid  = rgnid,
	model  = model,
	agent  = agent, 
	addr   = addr,
	handle = handle,
}

function inst:start(dispatch)
	return agent:start(self, dispatch)
end

function inst:stop(reason, message, ok)
	-- update userdata and clean external service 
	-- if session exited with runtime error
	if not ok then
		model:stop()
		agent:send(2, { reason=reason, message=message }, true)
	end
	-- agent.close dosen't take side-effect if be called more than once
	agent:close()
end

function inst:reconnect(val, sock)
	if val == secret then
		agent:replace(sock)
		return true
	end
	-- failed
	model:stop()
end


return inst
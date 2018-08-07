local xpcall = xpcall
local assert = assert
local traceback = debug.traceback
local time = os.time


-- 输入参数
local sock, secret = ...

-- 本地状态 
local context
local dispatch 
local session_response = {}

local overdrive = 0
local overdrive_ti = time() + 1


local function nextsecret()
	local key = secret + 9973
	secret = key
	return key
end

local function checkoverdrive()
	local now = time()
	if now >= overdrive_ti then
		overdrive = 0
		overdrive_ti = now + 1
	end
	overdrive = overdrive + 1
	assert(overdrive < 10, 'too many requests')
end

local function filter(cmd, req, session)
	checkoverdrive()
	-- response heartbeat directly
	if cmd == 'Heartbeat' then
		return table.empty
	end
	-- whether handled request
	local r = session_response[session]
	if r then
		return r
	end	
	-- do dispatch request
	local r = dispatch(context, cmd, req)
	session_response[session] = r
	session_response[session-1] = nil
	return r
end


-- 1 heartbeat
-- 2 systemerror
-- 3 echo

---@class agent
local inst = {}

function inst:start(ctx, disp)
	context = ctx
	dispatch = disp

	local ok,r = true
	for cmd,req,session in sock:start(nextsecret) do
		ok,r = xpcall(filter, traceback, cmd, req, session)
		if ok then
			sock:send(cmd, r, session)
			r = nil
		else
			break
		end
	end
	return (ok and sock:issockerror()), (r or sock:getlasterror())
end

function inst:send(id, data, shutdown)
	sock:send(id, data, 0, shutdown)
end

function inst:replace(newsock)
	sock:close()
	sock = newsock
end

function inst:close()
	sock:close()
end


return inst
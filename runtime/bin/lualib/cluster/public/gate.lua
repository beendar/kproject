local lnet = require 'lnet'
local socket = require 'cluster.public.socket'


local SECRET = 675438

local function genkey()
	return math.random(256,1024)
end

local function gencode(key)
	return key*SECRET-key
end

local function _open(host, ptype)
	local sock = socket.connect(host)
	if not sock then
		return nil, ('failed connect to host: %s'):format(host)
	end
	-- notify prototype and node information
	sock:send(ptype, 0, 
		'cluster.declare', {     -- (1)
			ptype = ptype,
			node  = lnet.env'node',
			type  = lnet.env'type',
			addr  = lnet.env'iendpt',
		})
	--get and answer question
	local _,cq = sock:recv()
	if not cq then
		sock:close()
		return nil, ('recv cluster question failed from host: %s'):format(host)
	end
	sock:send(ptype, 0,    -- (2)
		'cluster.answer', { 
			answer = gencode(cq.question) 
		}) 
	sock.node = cq.node
	return sock
end

local function open(host, ptype, chance)
	local sock,errmsg
	while not sock and chance > 0 do
		sock,errmsg = _open(host, ptype)
		chance = chance - 1
		lnet.sleep(sock and 0 or 1)
	end
	return sock,errmsg
end

local function watch(host, callback)
	return socket.listen(host, function(sock)
		-- recv handshake request
		local _,cd = sock:recv()    -- (1)
		if not cd then 
			sock:close()
			return
		end
		-- generate question and answer
		local qu = genkey()
		local an = gencode(qu)
		-- send question
		sock:send(cd.ptype, 0, 
			'cluster.question', { 
				question = qu,
				node = lnet.env'node', 
			})
		-- authenticate answer
		local _,ca = sock:recv()        -- (2)
		if not ca or ca.answer ~= an then 
			sock:close()
			return
		end
		sock.ptype = cd.ptype
		sock.node = cd.node
		sock.type = cd.type
		sock.addr = cd.addr
		callback(sock)
	end)
end


return {
	open  = open,
	watch = watch,
}

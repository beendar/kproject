local os = os

local pcall = pcall
local error = error

--clib
require 'lnet.terminal'.start()
require 'extend.system'
require 'extend.strpack'

--lualib
require 'extend.dump'
require 'extend.table'

--overwrite
PRINT = print
print = require 'lnet.logdriver'.print


--shortcut functions
function gc()
	collectgarbage'collect'
end

function gcc()
	print(collectgarbage'count')
end

function cls()
	os.execute'cls'
end

-- aux functions
function profile(f, ...)
	local st = os.now()
	local result = f(...)
	local str = ('elapsed: %.9f'):format(os.now() - st)
	print(str)
	return result
end

function difftime(uth, utm, uts)
	local dt  = os.date'*t'
	dt.hour = uth or 0
	dt.min = utm or 0
	dt.sec = uts or 0
	local tag = os.time(dt)
	local cur = os.time()
	return (tag > cur) and (tag-cur) or (tag+3600*24-cur)
end

function diffwdaytime( next_wday, uth, utm, uts )
	local dt  = os.date'*t'
	dt.hour = uth or 0
	dt.min = utm or 0
	dt.sec = uts or 0
	local tag = os.time(dt)
	local now = os.time()
	local isToday = tag > now

	local omd = isToday and 0 or 1
	local day = math.fmod( (7-(tonumber(os.date'%w') + omd - next_wday)) , 7 )
	local et = difftime( uth, utm, uts )
	return et + day * 3600 * 24
end

function randfunc(seed)
	local mul = assert(seed)
	return function(l, h)
		l = l or 0
		h = h or 0x7fffffff
		mul = mul * 0xefff % 0x7fffffff
		return l + mul % (h-l+1)
	end
end

-- custom error handling functions
local function filter(ok, ...)
	if ok then
		return true, ...
	end
	local _, _, errmsg = (...):find'([^\n]+)'
	return false, errmsg
end

function pcalli(f, ...)
	return filter(pcall(f, ...))
end

function asserti(b, errmsg)
	errmsg = errmsg or 'assertion failed!'
	if not b then
		error(errmsg, 0) -- without file and line in front of error message
	end
	return b
end


--appending function
require'lnet.sockdriver'.remotehost = function()
	local httpc = require 'http.client'
	local ok,body
	for try=1, 100 do
		ok,body = httpc.GET { host='pv.sohu.com', method='/cityjson' }
		if ok then
			local _,_,xaddr = body._RAWDATA:find'(%d+.%d+.%d+.%d+)'
			return xaddr
		else
			os.sleep(10)
		end
	end
	assert(ok, 'can not get external ip address')
end

function errorf(fmt, ...)
	local errmsg = fmt:format(...)
	error(errmsg, 3)
end

function errorfa(expr, fmt, ...)
	if not expr then
		local errmsg = fmt:format(...)
		error(errmsg, 3)
	end
end
local log        = require 'log'
local lnet       = require 'lnet'
local pack       = require 'lnet.seri'.pack
local zip        = require 'extend.zlib'.zip
local cluster    = require 'cluster.slave'
local multicastc = require 'cluster.multicastc'

local io = io
local table = table
local pairs = pairs
local ipairs = ipairs
local assert = assert
local loadfile = loadfile

local codeserver = 5
local codeclient = 6

local CACHE = {}

local function load()--{{{
	local chunk,err
	local codeset = {}
	for _,fp in ipairs(os.list({'../script'}, '.lua')) do
		chunk,err = loadfile(fp)
		if not chunk then break end
		local path = fp:gsub('../script/','') -- virtual filename
					   :gsub('.lua', '')
					   :gsub('[%/\\]', '.')
		codeset[path] = string.dump(chunk)
	end
	assert(chunk, err)
	local data, len = pack(codeset)
	CACHE.len = len
	CACHE.data = zip(data, len)
	return CACHE
end--}}}


local SLAVE = table.ensure()

local function genresult(result)
	if not result then return end
	local total = #result
	local success = 0
	local errmsg = {}
	for _,r in ipairs(result) do
		success = success + (r.ok and 1 or 0)
		errmsg[#errmsg+1] = not r.ok and r.err or nil
	end
	return total, success, errmsg[1] or ''
end

local function startup()

	-- preload all scripts
	load()

	-- register self with static handle value to cluster and setup message callback
	cluster.registerx('codeserver', codeserver, function(ctx)
		local type = ctx.type
		local addr = ctx.addr
		SLAVE[type][addr] = addr
		return CACHE
	end)

	-- DEBUG for virtual client calling
	cluster.registerx('codeserver.push', function(_, type)
		return push(type)
	end)

	-- clean slave when connection broken
	cluster.concern('passive.broken', function(addr, type) 
		SLAVE[type][addr] = nil 
	end)

	-- subscribe update command
	multicastc.subscribe('codeserver.update', function(type)
		local r = cluster.multicall(SLAVE[type], codeclient, 'lua', load())
		return genresult(r)
	end)
end

function showcode()--{{{
	local str = ('RLEN %.2fKB ZLEN %.2fKB'):format(CACHE.len/1024, #CACHE.data/1024)
	log.print(str)
end--}}}

function push(type)
	local r = multicastc.call('codeserver.update', type)
	local total = 0
	local success = 0
	local errmsg = ''
	for _,box in ipairs(r) do
		for i=1, #box, 3 do
			total = total + box[i]
			success = success + box[i+1]
			errmsg = box[i+2]
		end
	end
	local fmt = 
	[[
	nodetype: %s
	rate:     %.2f
	success:  %d
	failure:  %d
	errmsg:
	%s
	]]
	local tip = fmt:format(type:upper(), success/total*100, success, total - success, errmsg)
	log.print('\n%s', tip)
	return tip
end


return {
	startup = startup,
}

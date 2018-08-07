local lnet   = require 'lnet'
local unpack = require 'lnet.seri'.unpack
local unzip  = require 'extend.zlib'.unzip
local hotfix = require 'codecache.slave.hotfix'
local cluster = require 'cluster.slave'

local codeclient = 6

local PATH   = {}
local ENV    = {}
local CHUNK  = {}
local LOADED = {}
local LASTLOADED = {}
local GTABLE = { __index=_G }


local function querychunk(modname)
	--可能是完整路径
	local chunk = CHUNK[modname]
	if chunk then
		return chunk
	end
	--短路径 执行路径匹配
	for _,path in ipairs(PATH) do
		chunk = CHUNK[path..modname]
		if chunk then
			return chunk
		end
	end
end

local function loader(modname)
	CHUNK[#CHUNK+1] = modname
	print('loading...', modname)
	local chunk = assert(querychunk(modname), ('module chunk [%s]: can not found from cache'):format(modname))
	local env = ENV[modname] or setmetatable({}, GTABLE)
	setfenv(chunk, env)
	local mod = chunk() or true
	ENV[modname] = env
	LOADED[modname] = mod
	return type(mod)=='table' and LASTLOADED[modname] or mod
end

local function update(_, r)
	local code = unpack(unzip(r.len,r.data))
	--编译代码
	local LASTCHUNK = CHUNK
	CHUNK = code
	for path,bytecode in pairs(CHUNK) do
		CHUNK[path] = loadstring(bytecode, path)
	end
	--卸载由codecache加载的模块
	for modname in pairs(LOADED) do
		package.loaded[modname] = nil
	end
	--按上次记录的顺序开始重载
	LASTLOADED = LOADED
	LOADED = {}
	local ok,err = true,''
	for _,modname in ipairs(LASTCHUNK) do
		if querychunk(modname) then
			ok,err = pcall(require, modname)
			if not ok then break end
		end
	end
	--重载成功 开始更新
	if ok then
		ok,err = pcall(hotfix, LASTLOADED, LOADED)
	end
	--失败就回滚
	if not ok then
		table.copy(package.loaded, LASTLOADED)
		LOADED = LASTLOADED
		CHUNK  = LASTCHUNK
		return { err=err }
	end
	return { ok=true }
end


local codecache = {}

function codecache.call(modname, ...)
	local chunk = querychunk(modname)
	local env = setmetatable({}, GTABLE)
	setfenv(chunk, env)
	return chunk(...)
end

function codecache.addpath(path)
	if not PATH[path] then
		PATH[path] = true
		PATH[#PATH+1] = path .. '.'
	end
end

function codecache.startup(root)
	-- pull code the first time
	local codeserver = cluster.wait'codeserver'
	update(nil, cluster.call(codeserver, 'lua') )
	-- waiting for pushed command
	cluster.dispatch(codeclient, update)
	-- listen codeserver connection broken event
	cluster.concern('codeserver.broken', function()
		local next = cluster.wait'codeserver'
		cluster.send(next, 'lua')
	end)
	-- add additional loading path for short modname
	codecache.addpath('node_' .. lnet.env'type')
	-- add custom searcher
	table.insert(package.searchers, function() return loader end)
	-- start from root script
	require(root).startup()
end


--for shortname
package.loaded.codecache = codecache

return codecache

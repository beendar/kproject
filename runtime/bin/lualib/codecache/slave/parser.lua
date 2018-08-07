local print = require'lnet.logdriver'.print
local table = table
local next = next
local pairs = pairs
local type = type
local error = error
local getinfo    = debug.getinfo
local getupvalue = debug.getupvalue
local upvalueid  = debug.upvalueid


local PATH
local FUNC_PATH
local OBJ_TRACK
local UID_TRACK
local OVER_VIEW
local FUNC_VIEW
local CONFILICT_NAME
local SKIPPED_TABLE

local parse_table
local parse_function

local function addtrack(obj)
	local existed = OBJ_TRACK[obj]
	OBJ_TRACK[obj] = true
	return existed
end

local function deltrack(obj)
	OBJ_TRACK[obj] = nil
end

local function getfuncpath(f)
	local path = FUNC_PATH[f]
	if not path then
		path = getinfo(f, 'S').source
		FUNC_PATH[f] = path
	end
	return path
end

local function skipfunction(f)
	return (getfuncpath(f) ~= PATH)
end

local function skiptable(t)
	if table.ishotfix(t) then return false end
	-- 仅探测level1的元素
	-- 不跳过带元表的t的原因
	-- 1. 某些module用weaktable维护实例列表
	-- 2. 针对metadata 在level0 检测到第1个userdata就可跳过
	-- 3. 针对外部module 在level1 检测到第1个function就可跳过 
	-- if getmetatable(t) then return true end
	local k,v,s = next(t)
	while k and not s do
		s = (type(v) == 'userdata')
			or (type(v) == 'function' and skipfunction(v))
		k,v = next(t, k)
	end
	return s
end

local function istableskipped(t)
	return SKIPPED_TABLE[t]
end

local function addskippedtable(t)
	SKIPPED_TABLE[t] = true
end

function parse_table(name, t)
	--已分析的本地table 直接返回成功
	if addtrack(t) then 
		--print(('Local Table [%s] skipped'):format(name))
		return true 
	end
	--外部table 只分析一次
	if istableskipped(t) or skiptable(t) then
		deltrack(t)
		addskippedtable(t)
		--print(('External Table [%s] skipped'):format(name))
		return false
	end
	--开始分析本地table
	local k,v = next(t)
	while k do
		if type(v) == 'function' then
			parse_function(name..k, v)
		elseif type(v) == 'table' then
			parse_table(name..k, v)
		end
		k,v = next(t, k)
	end
	return true
end

function parse_function(name, f)

	if skipfunction(f) or addtrack(f) then
		--print(('Function [%s] skipped'):format(name))
		return
	end

	--该函数的私有视图
	FUNC_VIEW[f] = {}

	--开始解析函数的upvalue
	for idx=1, math.huge do
		local key, value = getupvalue(f, idx)
		local value_type = type(value)
		if not key then break end

		local mark = true
		if value_type == 'table' then
			mark = parse_table(key, value)
		end
		if value_type == 'function' then
			mark = false
			parse_function(key, value)
		end
		if mark then
			--处理名字冲突(upvalueid不同但名字相同)
			local id = upvalueid(f, idx)
			if not UID_TRACK[id] and OVER_VIEW[key] then
				CONFILICT_NAME[id] = name..'.'.. key
			end
			--取得正确的upvalue名字
			key = CONFILICT_NAME[id] or key
			--如果是第一次找到 就生成一个项 并存入overview
			OVER_VIEW[key] = OVER_VIEW[key] or { k=key, v=value, t=value_type }
			--函数视图引用综合视图中对应的项
			FUNC_VIEW[f][idx] = OVER_VIEW[key]
			--此id对应的upvalue已记录
			UID_TRACK[id] = true
		end
	end

end

local function getpath(var)
	if type(var) == 'function' then
		return getfuncpath(var)
	elseif type(var) == 'table' then
		for _, v in pairs(var) do
			if type(v) == 'function' then
				return getfuncpath(v)
			end
		end
	end
	local errmsg = ('param #1, function or table expect, got %s'):format(type(var))
	error(errmsg)
end

local function begin(var)
	if type(var)~='function' and type(var)~='table' then
		local errmsg = ('\n\tparam at #1, table or func expect, got %s'):format(type(var))
		error(errmsg)
	end
	FUNC_PATH = {}
	OBJ_TRACK = {}
	UID_TRACK = {}
	OVER_VIEW = {}
	FUNC_VIEW = {}
	CONFILICT_NAME = {}
	SKIPPED_TABLE = {}
	PATH = getpath(var)
	if type(var)=='table' then
		parse_table('', var)
	else
		parse_function('', var)
	end
end

local function finish()
	local view = { 
		overview = OVER_VIEW, 
		funcview = FUNC_VIEW 
	}
	--dump(view, '----------VIEW OF - '..PATH)
--	view = 
--	{
-- 		overview = {
--			[name] = {   <----------<-----------<----------<----
--          	v=(value of upvalue), t=(type of upvalue)       ^                    
--			}                                                   ^
--		},                                                      ^
--                                                              ^
--		funcview = {                                            ^
--			[func_address] = {                                  ^
--				--1 is upvalue index of this function           ^
--				[1] = (point to item in overview) --------->---->
--			}
--		}
--	}	
	PATH      = nil
	FUNC_PATH = nil
	OBJ_TRACK = nil
	UID_TRACK = nil
	OVER_VIEW = nil
	FUNC_VIEW = nil
	CONFILICT_NAME = nil
	SKIPPED_TABLE = nil 
	return view
end


return function(var)
	begin(var)
	return finish()
end

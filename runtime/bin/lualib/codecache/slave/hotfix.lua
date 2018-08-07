local copy  = table.copy
local type  = type
local pairs = pairs
local error = error
local assert = assert
local traceback = debug.traceback
local setupvalue = debug.setupvalue
local parse  = require'codecache.slave.parser'


local ERRFMT = 
[[
different upvalue type:
	module: %s
	name:   %s
	old:    %s
	new:    %s]]

local function check_upvalue(old, new)
	local ot,nt = old.t, new.t
	return (ot == nt)
		or (ot~='nil' and nt=='nil')
		or (ot=='nil' and nt~='nil')
end

local function check_overview(modname, viewold, viewnew)
	for name, new in pairs(viewnew) do
		local old = viewold[name]
		if old and not check_upvalue(old,new) then
			local errmsg = ERRFMT:format(modname, name, old.t, new.t)
			error(traceback(errmsg, 1), 0)
		end
	end
end

local function combine_upvalue(old, new)
	local ot,nt = old.t, new.t
	if ot==nt and ot=='table' then
		copy(old.v, new.v)
		new.v = old.v
	elseif ot~='nil' and nt=='nil' then
		new.v = old.v
	end
end

local function combine_overview(viewold, viewnew)
	for name, new in pairs(viewnew) do
		local old = viewold[name]
		if old then
			combine_upvalue(old, new)
		end
	end
end

local function patch(viewold, viewnew)
	--合并综合视图
	combine_overview(viewold.overview, viewnew.overview)
	--更新函数
	for f, upvalues in pairs(viewnew.funcview) do
		for idx, up in pairs(upvalues) do
			setupvalue(f, idx, up.v)
		end
	end
end


local ERRFMT = 
[[
different module return value type:
	module: %s
	old:    %s
	new:    %s]]

local function check_module(modname, oldval, newval)
	local oldtype = type(oldval)
	local newtype = type(newval)
	if oldtype ~= newtype then
		local errmsg = ERRFMT:format(modname, oldtype, newtype)
		error(traceback(errmsg, 1), 0)
	end
end

local function hotfix(oldmods, newmods)
	local viewofmods = {}

	--校验分析阶段
	for modname, modnew in pairs(newmods) do
		local modold = oldmods[modname]
		if modold and type(modold)~='boolean' then
			check_module(modname, modold, modnew)
			local viewold = parse(modold)
			local viewnew = parse(modnew)
			check_overview(modname, viewold.overview, viewnew.overview)
			viewofmods[viewold] = viewnew
		end
	end

	--更新阶段
	for viewold, viewnew in pairs(viewofmods) do
		patch(viewold, viewnew)
	end

	--保证table引用的不变性
	for modname, modnew in pairs(newmods) do
		local modold = oldmods[modname]
		if type(modold) == 'table' then
			newmods[modname] = table.copy(modold, modnew)
		end
	end
end


return hotfix
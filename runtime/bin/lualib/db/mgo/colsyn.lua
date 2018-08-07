local bson   = require'database.mongo.bson'
local table  = table
local type   = type
local next   = next
local ipairs = ipairs
local pairs  = pairs
local assert = assert
local setmetatable = setmetatable

local mt = {}
mt.__index = mt

function mt:__index(key)
	return self._hook[key] or mt[key]
end

function mt:__newindex(key, val)
	self._hook[key] = val
end

function mt:__ipairs()
	return ipairs(self._hook)
end

function mt:__pairs()
	return pairs(self._hook)
end

function mt:__len()
	return #self._hook
end


local function show(self)
	local col     = self._col
	local cond    = self._cond
	local subcond = self._filter.name

	local del = self._del
	local add = self._add
	local rem = self._rem
	local mod = self._mod

	if next(del) or next(add) or next(rem) or next(mod) then
		dump(cond, '@Table: ' .. col:namespace())

		local t = {}

		if next(del) then
			local tmp = {}
			for _,v in pairs(del) do
				tmp[v] = 'nil'
			end
			t['DELETE:'..subcond] = tmp
		end

		if next(add) then
			t.APPEND = add
		end

		if next(rem) then
			t.REMOVE = {}
			local tmp = table.clone(rem)
			for root,st in pairs(tmp) do
				for k in pairs(st) do
					st[k] = 'nil'
				end
				t.REMOVE[subcond..':'..root] = st
			end
		end

		if next(mod) then
			t.MODIFY = {}
			for root,st in pairs(mod) do
				t.MODIFY[subcond..':'..root] = st
			end
		end

		dump(t, '@Recoreds')
		print()
	end

end

function mt:rawset(key, value)
	self._hook._raw[key] = value
end

function mt:commit()
	show(self)

	local col     = self._col
	local cond    = self._cond
	local subcond = self._filter.name


	-- 记录删除
	if #self._del > 0 then
		cond[subcond] = { ['$in']=bson.array(self._del) }
		col:remove(cond)
	end

	-- 记录增加
	if #self._add > 0 then
		col:batch_insert( self._add )
	end

	-- 字段移除
	for root,srem in pairs(self._rem) do
		cond[subcond] = root
		col:update(cond, {['$unset']=srem})
	end

	--字段修改
	for root,smod in pairs(self._mod) do
		cond[subcond] = root
		col:update(cond, smod)
	end

	return self
end

function mt:clear()
	self._add = {}
	self._del = {}
	self._mod = {}
	self._rem = {}
end

function mt:save()
	self:commit():clear()
end

function mt:drop()
	local col = self._col
	local cond = self._cond
	local subcond = self._filter.name
	cond[subcond] = nil
	col:remove(cond)
end

local function callback(obj, path, val, depth)
	local convert = obj._filter.convert

	-- 字段级增删
	if depth > 0 then
		local _,_,root,left = path:find'(.-)%.(.+)'
		root = convert(root)
		if val ~= nil then
			local smod = obj._mod[root] or {}
			obj._mod[root] = smod		
			smod[left] = val
		else
			local srem = obj._rem[root] or {}
			obj._rem[root] = srem
			srem[left] = 1
		end
	-- 记录级增删
	else
		if val ~= nil then
			local add = obj._add
			add[#add+1] = val
		else
			local del = obj._del
			del[#del+1] = convert(path)
		end
	end
end

local _tonumber = require 'numerics'

local function _tostring(v)
	return v
end


--collection synchro
return function(t, col, cond, subcond, subtype)
	assert(type(subcond) == 'string')
	assert(subtype == 's' or subtype == 'n')
	local obj = {
		_col = col,
		_add = {},  -- 记录追加
		_del = {},  -- 记录删除
		_mod = {},  -- 字段修改
		_rem = {},  -- 字段移除
		_cond = table.clone(cond),
		_filter = {
			name = subcond,
			convert = subtype == 's' and _tostring or _tonumber
		}
	}

	obj._hook = table.hook(t, callback, obj)
	return setmetatable(obj, mt)
end

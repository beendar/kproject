local type  = type
local next  = next
local setmetatable = setmetatable
local table = table

local mt = {}

function mt:__index(key)
	return self._hook[key] or mt[key]
end

function mt:__newindex(key, val)
	self._hook[key] = val
end

function mt:__ipairs()
	return next, self._hook._raw, nil
end

function mt:__pairs()
	return next, self._hook._raw, nil
end

function mt:__len()
	return #self._hook._raw
end

local function show(self)
	local col  = self._col
	local cond = self._cond
	local rem  = self._rem
	local mod  = self._mod

	if next(rem) or next(mod) then
		dump(cond, '@Table: ' .. col:namespace())
		local tmp = table.clone(rem)
		for k in pairs(tmp) do
			tmp[k] = 'nil'
		end
		table.copy(tmp, mod)
		dump(tmp, '@Docment')
		print()
	end
end

function mt:rawset(key, value)
	self._hook._raw[key] = value
end	

function mt:commit()
	show(self)

	local col  = self._col
	local cond = self._cond
	local rem  = self._rem
	local mod  = self._mod

	if next(rem) then
		col:update(cond, {['$unset']=rem})
	end
	
	if next(mod) then
		col:update(cond, mod)
	end

	return self
end

function mt:clear()
	self._mod = {}
	self._rem = {}
end

function mt:save()
	self:commit():clear()
end

function mt:drop()
	local col = self._col
	local cond = self._cond
	col:remove(cond)
end

local function callback(obj, path, val)
	if type(val) ~= 'nil' then
		obj._mod[path] = val
	else
		obj._rem[path] = 1
	end
end


--document synchro
return function(t, col, cond)
	local obj = {
		_col  = col,
		_mod  = {},
		_rem  = {},
		_cond = cond
	}
	obj._hook = table.hook(t, callback, obj)
	return setmetatable(obj , mt)
end

local type    = type
local next    = next
local pairs   = pairs
local ipairs  = ipairs
local assert  = assert
local error   = error
local select  = select
local tremove = table.remove
local setmetatable = setmetatable
local getmetatable = getmetatable


local function makepath_r(t, k)
	local sb = setmetatable({}, {
			__index = function(st,sk)
				local path = k .. sk .. '.'
				st[sk] = path
				return path
			end
		})
	t[k] = sb
	return sb
end

local function makepath_w(t, k)
	local sb = setmetatable({}, {
			__index = function(st,sk)
				local path = k .. sk
				st[sk] = path
				return path
			end
		})
	t[k] = sb
	return sb
end

local PR = setmetatable({}, {
		__mode = 'kv',
		__index = makepath_r,
	})

local PW = setmetatable({}, {
		__mode = 'kv',
		__index = makepath_w,
	})


local mt = {}

local function _set_hook(raw, context, path, depth)
	local h = {
		_raw = raw,
		_context = context,
		_path = path,
		_depth = depth,
	}

	context[raw] = h
	return setmetatable(h, mt)
end

function mt:__index(k)
	local v = self._raw[k]
	if type(v) ~= 'table' then
		return v
	end
	local context = self._context
	return context[v] or _set_hook(v, context, PR[self._path][k], self._depth + 1)
end

function mt:__newindex(k, v)
	self._raw[k] = v

	local cb = self._context._cb
	local ud = self._context._ud
	cb(ud, PW[self._path][k], v, self._depth)
end

function mt:__ipairs()
	return next, self._raw, nil
end

function mt:__pairs()
	return next, self._raw, nil
end

function mt:__len()
	return #self._raw
end

function table.hook(t, cb, ud)
	local ctx = setmetatable({_cb=cb, _ud=ud}, weak_k)
	return _set_hook(t, ctx, '', 0)
end


local mt = {}
mt.__index = mt

function mt:set(key, val, on_dropkey)
    self.list[key] = {
        val = val,
        on_dropkey = on_dropkey
    }
end

function mt:get(key)
    local entry = self.list[key]
    if entry then
        return entry.val
    end
end

function mt:drop(key)
    local entry = self.list[key]
    if entry then
        self.list[key] = nil
        local val = entry.val
        local on_dropkey = entry.on_dropkey
        if on_dropkey then
            on_dropkey(self.ud, val)
        end
        return val
    end
end

function mt:clear()
    for key in pairs(self.list) do
        self:drop(key)
    end
end

function table.keysensi(ud)
	return setmetatable({
        ud = ud,
        list = {}
    }, mt)

end


local weak_k = { __mode='k' }
local weak_v = { __mode='v' }
local weak_kv = { __mode='kv' }

function table.weak(t)
	return setmetatable(t or {}, weak_v)
end

function table.removeif(t, filter, ...)
	for i,v in ipairs(t) do
		if filter(v, ...) then 
			return tremove(t, i) 
		end
	end
end

function table.clear(t)
	for k,_ in pairs(t) do
		t[k] = nil
	end
end

function table.toarray(hash)
	local a = {}
	for _,v in pairs(hash) do
		a[#a+1] = v
	end
	return a
end

function table.totable(array, key)
	local t = {}
	for _,v in pairs(array) do
		if key then
			t[v[key]] = v
		else
			t[v] = true
		end
	end
	return t
end

local function _clone_table(source)
	local t = {}
	for k,v in pairs(source) do
		if type(v) ~= 'table' then
			t[k] = v
		else
			t[k] = _clone_table(v)
		end
	end
	return t
end

function table.clone(source)
	return _clone_table(source)
end

function table.copy(dest, source, filter)
	if not filter then
		for k,v in pairs(source) do
			dest[k] = v
		end
	else
		for k,v in pairs(source) do
			dest[k] = filter(v)
		end
	end
	return dest
end

function table.append(dest, source, filter)
	if not filter then
		for _,v in pairs(source) do
			dest[#dest+1] = v
		end
	else
		for _,v in pairs(source) do
			dest[#dest+1] = filter(v)
		end
	end
	return dest
end

function table.count(t)
	local n = 0
	for _,_ in pairs(t) do
		n = n + 1
	end
	return n
end

function table.sum(t)
	local sum = 0
	for _, n in pairs(t) do
		sum = sum + n
	end
	return sum
end

function table.readonly(t)
	return setmetatable({}, {
		__index = t or {},
		__newindex = function() 
			error(debug.traceback('modify readonly table',3), 2) 
		end
		})
end

table.empty = table.readonly()

function table.ensure(t)
	return setmetatable(t or {}, {
		__index = function(t, k)
			t[k] = {}
			return t[k]
		end
		})
end

function table.foreach(t, f)
	for k,v in pairs(t) do
		f(k,v)
	end
	return t
end

function table.find(array, dest)
	for idx, v in ipairs(array) do
		if v == dest then return idx end
	end
end

function table.grab(t, ...)
	for n=1, select('#', ...) do
		t[#t+1] = select(n, ...)
	end
	return t
end

function table.keys(t)
	local r = {}
	for k in pairs(t) do
		r[#r+1] = k
	end
	return r
end

function table.values(t)
	local r = {}
	for _,v in pairs(t) do
		r[#r+1] = v
	end
	return r
end

table.unpack = unpack

local mt_hotfix = {}

function table.hotfix(t)
	assert(not getmetatable(t), 't has been attached a metatable')
	return setmetatable(t, mt_hotfix)
end

function table.ishotfix(t)
	return (getmetatable(t) == mt_hotfix)
end
local assert = assert
local setmetatable = setmetatable
local future       = require 'db.mgo.future'
local sdocument    = require 'db.mgo.docsyn'
local scollection  = require 'db.mgo.colsyn'


local mt = {}
mt.__index = mt

function mt:addspec(colname, key, valtype)
	self._spec[colname] = {
		key = key,
		valtype = valtype,
	}
end

function mt:getspeckey(colname)
	local spec = assert(self._spec[colname], 'mgo.proxy.getspeckey: spec is empty')
	return spec.key
end

function mt:insert(colname, doc)
	local col = self._db:getcol(colname)
	local spec = assert(self._spec[colname], 'mgo.proxy.insert: spec is empty')
	if spec.key then
        return col:batch_insert(doc)
	end
	col:insert(doc)
end


local default = { _id=0 }

function mt:load(colname, cond, selector)
	selector = selector or default
	local col = self._db:getcol(colname)
    local spec = assert(self._spec[colname], 'mgo.proxy.load: spec is empty')
	if spec.key then
		local cursor = col:find(cond, selector)
		return cursor:totable(spec.key)
	end
	return col:find_one(cond, selector)
end

function mt:future()
	return future(self)
end

function mt:bind(t, colname, query)
	local col = self._db:getcol(colname)
	local key = self._spec[colname].key
	local valtype = self._spec[colname].valtype
	if key then
		return scollection(t, col, query, key, valtype)
	end
	return sdocument(t, col, query)
end


return function(db)
	return setmetatable({
			_db = db,
			_spec = {},
		}, mt)
end

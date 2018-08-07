local redis
local shift = 1200000

local tostring = tostring

local typekey = {
    user = 'geniduser',
    clan = 'genidclan',
}

local function ensurekey(type)
	local key = typekey[type]
	if not key then
		local errmsg = ('invalid genid type: %s'):format(type)
		error(errmsg, 3)
	end
	return key
end

local function next(type)
    local key = ensurekey(type)
    local _, id = redis:incr(key)
    return tostring(id + shift)
end

local function startup(obj)
    redis = obj
end


return {
    startup = startup,
    next = next,
}
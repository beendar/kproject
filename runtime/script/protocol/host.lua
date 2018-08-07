local PROTO = {}


local function register(id, name)
    local p = {
		id = id,
		name = name,
		S = string.format('netprotocol.%sToS', name),
		C = string.format('netprotocol.%sToC', name),
	}
	PROTO[id]   = p
	PROTO[name] = p
end

local function query(key)
    return PROTO[key]
end


return {
    register = register,
    query = query,
}
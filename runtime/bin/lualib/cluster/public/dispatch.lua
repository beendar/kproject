local pcall = pcall
local pairs = pairs
local assert = assert

local DISPATCH = {}

function showd()
	dump(DISPATCH)
end

local function response(ok, ...)
	if ok then
		return ...
	end
	return nil, ...
end

local function dispatch(handle, f)
	DISPATCH[handle] = f
end

local function dispatch_message(handle, ctx, ...)
	local f  = DISPATCH[handle]
	if f then
		return response(pcall(f, ctx, ...))
	end
	return nil, 'can not found service'
end


return {
	dispatch = dispatch,
	message  = dispatch_message,
}

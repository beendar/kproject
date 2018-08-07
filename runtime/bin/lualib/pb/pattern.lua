local unpack = require'pb.core'.unpack

local pattern_lookup = {}

local function ensure_pattern(prefix, field)
	local t = pattern_lookup[prefix]
	if (not t) then
		t = {}
		pattern_lookup[prefix] = t
	end

	local pattern = t[field]
	if (not pattern) then
		pattern = prefix .. field
		t[field] = pattern
	end

	return pattern
end


local obj = {}

function obj:set(pre, buf, len)
	self.pre = pre
	self.buf = buf
	self.len = len
	return self
end


function obj:__call(field)
	local pattern = ensure_pattern(self.pre, field)
	return unpack(pattern, self.buf, self.len)
end

return setmetatable(obj, obj)

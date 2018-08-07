local tonumber = tonumber
local capture


local filter_field = --{{{
{
	["content-type"] = function(s)
		return {
			urlencoded = (s:find'urlencoded'),
			charset    = capture(s, 'charset=(%C+)') or 'ansi'
		}
	end,

	["transfer-encoding"] = function(s)
		return (s:gsub('%s', ''))
	end,

	["content-length"] = function(s)
		return tonumber(s)
	end,
}--}}}

function capture(s, pattern, pos)--{{{
	local _, _, a,b,c = s:find(pattern, pos or 1)
	return a,b,c
end--}}}

local function urlencode(s)--{{{
     return (s:gsub("([^%w%.%-%_])",
				function(c)
					return ("%%%02X"):format(c:byte())
				end))
end--}}}

local function urldecode(s)--{{{
	return (s:gsub('%%(%w%w)',
				function(c)
					return string.char(tonumber(c, 16))
				end))
end--}}}

local function parseline(line)
	local k,v = capture(line, '(.-):%s(.+)')
	if k then
		k = k:lower()
		local f = filter_field[k]
		return k, f and f(v) or v
	end
end


return {
	capture   = capture,
	urlencode = urlencode,
	urldecode = urldecode,
	parseline = parseline,
}

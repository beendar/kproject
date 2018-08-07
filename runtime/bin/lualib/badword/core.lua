local utf8 = require 'extend.utf8'
local tree = require 'badword.tree'

local en     = '[^\65-\90\97-\122]'
local ch     = '[^\128-\244]'
local en_num = '[^\48-\57\65-\90\97-\122]'
local ch_num = '[^\48-\57\128-\244]'

local function _find(s)
	local len = utf8.len(s)
	for n=1, len do
		local level = tree
		for p=n, len do
			local slice = utf8.sub(s, p, p)
			level = level[slice]
			if level then
				if level._xend then
					return true
				end
			else
				break
			end
		end
	end
end



return {
	find = function(s)
		s = s:lower()
		return _find(s)
			or _find( s:gsub(ch, '') )
			or _find( s:gsub(en, '') )
			or _find( s:gsub(ch_num, '') )
			or _find( s:gsub(en_num, '') )
	end
}

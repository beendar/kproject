local metadata  = require 'metadata'
local maxlvdata = metadata.stoneCommon[1].start2lv
local expdata   = metadata.stoneCommon[1].exp



---@class stone
local interface = {}

function interface:addlevelexp(total)
	total = total + self.exp

	local startval = total

	local maxlevel = maxlvdata[self.star]
	local level = self.level

	while expdata[level] and total >= expdata[level] and level < maxlevel do
		total = total - expdata[level]
		level = level + 1
	end
	
	self.exp = total	
	self.level = level

	return (startval - total)
end

function interface:upgrade()
	local nextstar = self.star + 1
	self.star = nextstar
	return nextstar
end

function interface:avaliable()
	return self.rela == 0
end

function interface:set(roleid)
	self.rela = roleid
end

function interface:unset()
	self.rela = 0
end


return interface
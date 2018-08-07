local time = os.time
local difftime = difftime


local gcdata = require 'metadata'.gamecommon[1]


---@class friend
local interface = {}

function interface:remove()
	self.Model.base:incfriendn(-1)
	self.Model.friend[self.fpid] = nil
end

function interface:check()
	return (self.status == 0)
end

function interface:apply(ok)
	if ok then
		self.status = 0
	else
		self:remove()
	end
	return ok
end

function interface:present_ap()

	local base = self.Model.base
	if not base:inc_present_ap_count() then
		return nil, 'avaliable present count has been used out'
	end

	local now = time()
	if now < self.ap_ti then
		return nil, 'has been presented for this guy'
	end

	local next_ti = now + difftime(0,0,0)
	self.ap_ti = next_ti

	return gcdata.present_ap_pt, next_ti
end


return interface
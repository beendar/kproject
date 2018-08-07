local random = math.random
local assert = assert
local setmetatable = setmetatable

local metadata  = require 'metadata'
local expdata   = metadata.characterOther[1].exp_need
local maxsklv   = metadata.characterOther[1].ability_limit
local maxlvdata = metadata.characterCommon
local roledata  = metadata.character
local holydata  = metadata.holyplace
local sanctuarydata = metadata.sanctuary


---@class role
local interface = {}


-- 增加等级经验
function interface:addlevelexp(total)
	total = total + self.level_exp

	local maxlv = maxlvdata[self.quality].LVMAX
	local lv = self.level

	while expdata[lv] and total >= expdata[lv] and lv < maxlv do
		total = total - expdata[lv]
		lv = lv + 1
	end
	
	self.level = lv

	if lv == maxlv then
		self.level_exp = 0
	else
		self.level_exp = total	
	end
end

-- 增加好感度经验
function interface:addfavourexp(total)
	total = total + self.favour_exp

	local max  = metadata.characterOther[1].love_max
	local cost = metadata.characterOther[1].love_exp

	local last = self.favour
	while self.favour < max and total >= cost do
		total = total - cost
		self.favour = self.favour + 1
	end

	self.favour_exp = total

	-- 随机给一个未满级的技能升级
	local t = {}
	t[1] = {id=1, level=self.skill[1].level}
	t[2] = {id=2, level=self.skill[2].level}
	t[3] = {id=3, level=self.skill[3].level}

	if t[3].level == maxsklv then
		table.remove(t, 3)
	end
	if t[2].level == maxsklv or self.awake==0 then
		table.remove(t, 2)
	end
	if t[1].level == maxsklv then
		table.remove(t, 1)
	end
	for n=1, self.favour - last do
		if #t == 0 then break end
		local pos = random(1, #t)
		local val = t[pos]
		val.level = val.level + 1
		self.skill[val.id].level = val.level 
		if val.level == maxsklv then
			table.remove(t, pos)
		end
	end
end

-- 穿戴石头
function interface:insertstone(pos, sn)
	-- 把上一个取了
	local laststone = self.Model.stone[self.stone[pos]]
	if laststone then
		laststone:unset()
	end

	-- 更新石头状态
	local stone = self.Model.stone[sn]
	if stone then
		assert(stone:avaliable(), 'stone is using by other role')
		stone:set(self.tid)
	end

	-- 更新角色装备孔
	self.stone[pos] = sn>0 and sn or 0
end

-- 升级圣域
function interface:upgradesanctuary(index)
	-- 检查角色等级
	local sanctumid = roledata[self.tid].SanctumID
	local nodeid = holydata[sanctumid].place[index]
	local lvneed = sanctuarydata[nodeid].limit
	assert(self.level >= lvneed, 'role level is not enough')

	-- 扣减金币
	local list = self.sanctuary
	local slv = list[index]
	local goldneed = -sanctuarydata[nodeid].cast[slv+1]

	self.Model.bag:addcoin('gold', goldneed)

	-- 圣域等级+1
	list[index] = slv + 1
end

function interface:addmask( tag )
	local mask = self.mask or 0
	mask = bit.bor(mask, bit.lshift(1, tag))
	self.mask = mask
end

function interface:removemask( tag )
	local mask = self.mask or 0
	mask = bit.bxor(mask, bit.lshift(1, tag))
	self.mask = mask
end

function interface:getmask( tag )
	local mask = self.mask or 0
	if not tag then
		return mask
	end
	return bit.band(mask, bit.lshift(1, tag)) > 0
end


return interface
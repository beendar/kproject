local type = type
local pairs = pairs
local error = error
local setmetatable = setmetatable
local metadata = require 'metadata'
local itemdata = metadata.item
local stonedata= metadata.itemstone

local coinToId = {
	gold = 30000,
	rmb = 30001,
	jungle = 30003,
	clan = 30004,
	fogmaze = 30006,
	kagutsu = 30007,
	kingbattle = 30008,
	[30000] = 30000,
	[30001] = 30001,
	[30003] = 30003,
	[30004] = 30004,
	[30006] = 30006,
	[30007] = 30007,
	[30008] = 30008,
}

local function getcoinid(coin)
	local tid = coinToId[coin]
	if not tid then
		local errmsg = ('invalid coin name or id: %s'):format(coin)
		error(errmsg, 2)
	end
	return tid
end


---@class bag
local interface = {}

---@param list tItem[]
function interface:removeitem(list)
	for _,item in pairs(list) do
		local iid  = item.tid
		local left = self[iid].count - item.count
		if left < 0 then
			local errmsg = ('item of id[%d] is not enough'):format(iid)
			error(errmsg, 2)
		end
		if left > 0 then
			self[iid].count = left
		else
			self[iid] = nil
		end
	end
end

function interface:incitem( tid, count )
	local entry = self[tid]
	if entry then
		entry.count = entry.count + count
		assert(entry.count >= 0)
	else
		assert(count >=0 )
		self[tid] = {
			tid = tid,
			count = count
		}
	end
end

---@param list tItem[]
function interface:additem(list)
	for _,item in pairs(list) do
        local tid = item.tid
		local entry= self[tid]
		if entry then
			entry.count = entry.count + item.count
		else
			self[tid] = item
		end
	end
end

---@param list tStone[]
function interface:addstone(list)
	local stonelist = self.Model.stone
	for _, stone in pairs(list) do
		stonelist[stone.sn] = stone
	end
end

---@param list tItem[]
function interface:sellitem(list)
    self:removeitem(list)
	local gold = 0
	for _,item in pairs(list) do
		local tid = item.tid
		local count = item.count
		gold = gold + count*itemdata[tid].price
	end
	self:addcoin('gold', gold)
    return gold
end

---@param list number[]
function interface:sellstone(list)
	local stonelist = self.Model.stone
	local gold = 0
	for _, sn in pairs(list) do
		local tid = stonelist:rawget(sn).tid
		stonelist[sn] = nil
		gold = gold + stonedata[tid].price
	end
	self:addcoin('gold', gold)
    return gold
end


--! 代币接口
function interface:addcoin(coin, count)
	local entry = self[getcoinid(coin)]
	entry.count = entry.count + count
	assert(entry.count >= 0, 'coin count can not less than zero')
	return entry.count
end

function interface:setcoin(coin, count)
	assert(count >= 0, 'coin count can not less than zero')
	local entry = self[getcoinid(coin)]
	entry.count = count
end

function interface:getcoin(coin)
	local entry = self[getcoinid(coin)]
	return entry.count
end


return interface
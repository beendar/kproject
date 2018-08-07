local table = table
local string = string
local assert = assert
local error = error

-- 公共函数定义
--!@brief: 检查随机掉落池元素数量是否平衡
local function ispoolbalance(pool, step)
	return (#pool % step == 0)
end

--!@brief: 求得掉落池总权重
local function sumweight(pool, step, offset)
	local total = 0
	for idx=1, #pool, step do
		total = total + pool[idx+offset]
	end
	return total
end

local function unpack(t, a, b)
	local r = {}
	for idx=a, b do
		r[#r+1] = t[idx]
	end
	return table.unpack(r)
end

--!@brief: 将掉落池转换为易用格式
--!@remark: 约定转换器的返回值 必须包含g字段表示权重
local function convertpool(pool, step, convertor)
	local total = 0
    local list = {}
	for idx=1, #pool, step do
		local entry = convertor(unpack(pool, idx, idx+step-1))
		total = total + entry.g
		entry.g = total
		table.insert(list, entry)
	end
	return {
		total = total,
		list  = list,
	}

end

-- 加载自定义常量配置
require 'gamedata.constant'


-- 将关卡配置转换成易查的格式
local metadata    = require 'metadata'
local dungeondata = metadata.pvedungeon
local chapterdata = metadata.pvechapter
local actiondata  = metadata.pveaction

local empty = {}
local stageinfo = {}
local actioninfo = {}

for dungeonid, dungeon in pairs(dungeondata) do
	local chapters = dungeon.chapters
	for chapterindex, chapterid in ipairs(chapters) do
		local actions = chapterdata[chapterid].actions
		for actionindex, actionid in ipairs(actions) do
			actioninfo[actionid] = {
				index = actionindex,
				chapterid = chapterid
			}
			local action = actiondata[actionid] or empty
			for diffculty=1, 3 do
				local levels = action['levels_'..diffculty] or empty
				for stageindex, stageid in ipairs(levels) do
					stageinfo[stageid] = {
						dungeonid = dungeonid,
						chapterid = chapterid,
						actionid = actionid,
						actionindex = actionindex,
						diffculty = diffculty,
						nextstageid = levels[stageindex+1],
						nextactionid = actions[actionindex+1],
						nextchapterid = chapters[chapterindex+1],
					}
				end
			end
		end
	end
end

metadata.new('stageinfo', stageinfo)
metadata.new('actioninfo', actioninfo)


-- 将卡池转换成易用的格式
local roledata = metadata.character

local function checkroleid(tid)
	if not roledata[tid] then
      	local msg = ('extract pool, role of tid[%d] do not exist'):format(tid)
       	error(msg)
	end
	return tid
end

local result = {}
for id, entry in ipairs(metadata.extract) do
	if not ispoolbalance(entry.info, 2) then
		local errmsg = string.format('extract pool of id %d is not balance', id)
		error(errmsg)
	end
	result[id] = convertpool(entry.info, 2, 
		function(tid, g)
			return { tid=checkroleid(tid), g=g }
		end)
end

metadata.new('extract', result)

-- 额外的悬赏配置格式
local jungledata = metadata.jungle
local type2data = {}
for tid,v in pairs(jungledata) do
	if not type2data[v.jtype] then
		type2data[v.jtype] = {}
	end

	if not type2data[v.jtype][v.level] then
		type2data[v.jtype][v.level] = {}
	end

	local t = table.clone(v)
	t.tid = tid
	table.insert(type2data[v.jtype][v.level],t)
end
metadata.new('jungle4type', type2data)


-- 转换商店商品列表配置
local goodsdata = metadata.goods

local function checkgoodsid(tid)
	if not goodsdata[tid] then
		local errmsg = string.format('goods id %d is not exists', tid)
		error(errmsg)
	end
	return tid
end

local function convertgoodspool(id, pool)
	if not ispoolbalance(pool, 2) then
		local errmsg = string.format('shop id %d, goods pool config is not balance', id)
		error(errmsg)
	end

	-- 求总权重
	local g = sumweight(pool, 2, 1)

	-- 固定列表
	if g == 0 then
		local r = {}
		for n=1, #pool, 2 do
			local goodsid = checkgoodsid(pool[n])
			r[goodsid] = goodsid
		end
		return r
	end

	-- 随机列表
	if g > 0 then
		return convertpool(pool, 2, 
			function(tid, g)
				return { tid=checkgoodsid(tid), g=g }
			end)
	end
end

local result = {}
for id, entry in pairs(metadata.mall) do
	local shop = table.clone(entry)
	shop.goodsID = convertgoodspool(id, shop.goodsID)
	result[id] = shop
end

metadata.new('mall', result)

-- 转换宝箱掉落池
local result = {}

for id, entry in pairs(metadata.chestdrop) do
	if not ispoolbalance(entry.info, 3) then
		local errmsg = string.format('chest pool of id %d is not balance', id)
		error(errmsg)
	end
	result[id] = convertpool(entry.info, 3, 
		function(tid, count, g)
			return { tid=tid, count=count, g=g }
		end)
end

metadata.new('chestdrop', result)
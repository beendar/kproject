local time = os.time
local ipairs = ipairs
local util = require 'gamesys.util'

local metadata = require 'metadata'
local gcdata   = metadata.gamecommon[1]
local plvdata = metadata.playerlevelattr

---@type constant
local constant = metadata.constant

-- 玩法ID
local PMETHOD_DUNGEON = constant.PMETHOD_DUNGEON -- 副本玩法 (主线/日常/挑战/新王)
local PMETHOD_FOGMAZE = constant.PMETHOD_FOGMAZE -- 雾之迷宫

-- 副本类型ID
local PDUNGEON_MAIN     = constant.PDUNGEON_MAIN   -- 主线副本
local PDUNGEON_DAILY    = constant.PDUNGEON_DAILY  -- 日常副本
local PDUNGEON_VERSUS   = constant.PDUNGEON_VERSUS -- 挑战副本
local PDUNGEON_KING     = constant.PDUNGEON_KING   -- 新王副本


local function baseinfo(pid, rgnid)
	local now = time()
	return {
		pid         = pid,
		rgnid       = rgnid,
		gensn       = 1,
		create_time = now,
		online      = now,
		offline     = now,
		nickname    = nil,
		energy      = plvdata[1].energyMax,
		energy_ti   = now,
		plv         = 1,
		plv_exp     = 0,
		committal_count = 3,
		present_ap_count = 0,
		present_ap_ti = 0,
		headid = 1,
		mask = 0,

		jungle_ti   = 0,	--丛林悬赏刷新时间
		jungle_exp = 0,		--经验
		jungle_finish_count = 0,	--丛林悬赏累计完成次数（每周重置）
		jungle_money_times = 0,	--丛林悬赏赏金任务领取次数

		kagutsu_open = 4,--迦具都玩法，默认解锁第一关

		guide_id = 1,	--默认解锁引导系统第一个引导组

		clan_req_ti = 0,    -- 公会可用申请数重置超时
		clan_req_count = 0, -- 公会可用申请数

		energy_buy_ti = 0, -- 钻石买体力
		energy_buy = 0,
		gold_buy_ti = 0, -- 钻石买金币
		gold_buy = 0,

		-- 系统字段 (不参与传输)
		sysfriendn = 0,  -- 好友计数
		sysmailid  = '', -- 领受的最后一封系统邮件id

		daily_challenge = {}, --每日挑战数据
		daily_challenge_ti = os.time() + difftime(),

	        -- TODO: delete 版署需求
		extract_chance = 0,
		extract_ti = 0,
	}
end

local function itembag(pid, rgnid)
   local bag = { 
	   pid = pid, 
	   rgnid = rgnid,
	   -- 初始化代币条目
	   [30000] = { tid=30000, count=gcdata.initGold },
	   [30001] = { tid=30001, count=gcdata.initRMB },
	   [30003] = { tid=30003, count=0 }, -- 丛林币
	   [30004] = { tid=30004, count=0 }, -- 社团币
	   [30006] = { tid=30006, count=0 }, -- 雾币
	   [30007] = { tid=30007, count=0 }, -- 家具都币
	   [30008] = { tid=30008, count=0 }, -- 挑战币
	}
	for _,entry in ipairs(gcdata.initItem) do
        local tid= entry.tid
		local count = entry.count
		bag[tid] = util.newitem(tid, count)
	end
    return bag
end

local function rolelist(pid, rgnid)
	local list = {}
	for _,tid in ipairs(gcdata.initRole) do
        list[tid] = util.newrole(pid, rgnid, tid)
	end
    return list
end

local function stonelist(pid, rgnid, sn)
    local list = {}
	for _,tid in ipairs(gcdata.initStone) do
		sn = sn + 1
		list[sn] = util.newstone(pid, rgnid, tid, sn)
	end
    return list, sn
end

local function committallist(pid, rgnid, sn)
	local list = {}
	for _, tid in ipairs({1,2,3,4,5,6,7,8,9,10}) do
		sn = sn + 1
		list[sn] = util.newcommittal(pid, rgnid, tid, sn)
	end
	return list, sn
end

local function new(pid, rgnid)

	-- region archive base information
    local base = baseinfo(pid, rgnid)

	-- default item bag
	local bag = itembag(pid, rgnid)

	-- default playing method
	local pmethod = {
		[PMETHOD_DUNGEON] = util.newpmethod(pid, rgnid, PMETHOD_DUNGEON),
		[PMETHOD_FOGMAZE] = util.newpmethod(pid, rgnid, PMETHOD_FOGMAZE),
	}

	-- default chapter
    local chapter = {
		[1] = util.newchapter(pid, rgnid, PDUNGEON_MAIN, 1, 1)
	}

    -- default rolelist
	local role    = rolelist(pid, rgnid)

	-- default stone list
	local stone,sn = stonelist(pid, rgnid, base.gensn)

	-- 不再需要初始化了，依赖配置驱动
	-- default committal list
	-- local committal,sn = committallist(pid, rgnid, sn)


	-- update instance serial number counter
	base.gensn = sn

    -- return as archive
	-- keeps same fieldname with database tablename
	return {
		base = base,
		bag = bag,
		pmethod = pmethod,
		chapter = chapter,
		role = role,
		stone = stone,
		friend = {},
		committal = {},
		jungle = {},
		kagutsu = {
			pid = pid, 
			rgnid = rgnid,
		},
		mission = {
			pid = pid,
			rgnid = rgnid,
			normal = {	--根据配置以及complete的情况，确定是否显示，有数据不代表任务就是开放的			id,count 4字节压缩
				--[[
					tid = 1,
					count = 10,
					complete = false,
					got_reward = false,
				]]
			},
			activity = {},	--活动任务
			daily = {},
			weekly = {},	--如果有，就要显示
			daily_point = 0,
			weekly_point = 0,
			daily_et = 0,
			weekly_et = 0,
			complete = {},
			daily_point_reward = {},
			weekly_point_reward = {},
		},
		mallrecord = {
			pid=pid,
			rgnid=rgnid,
		},
		kingbattle = {
			pid=pid,
			rgnid=rgnid,
			finish_ti = 0,
			plv = 1,
			--[[
			-- only server
			nickname = '',
			guard_ti = 0,
			nonce = math.random(1,1000),
		 	-- shared
			refresh_ti = -1,
			won = 0,
			score = 0,
			won = 0,
			score = 0,
			formation_atk = {tid_king, tid1, ..., tid5},
			formation_def = {tid_king, tid1, ..., tid5},
			enemies = {
				[1] = {
					plv, nickname, tid, beat, -- for client,
					pid, rgnid, -- for server
				}
			}
			--]]
		},
		island = {
			pid=pid,
			rgnid=rgnid,
			devices = {}
		}
	}
end


return {
    new = new,
}
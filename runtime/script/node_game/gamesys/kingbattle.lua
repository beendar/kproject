local bson = require 'database.mongo.bson'
local cluster = require 'cluster.slave'
local location = require 'pub.location'

local kbutil = require 'gamesys.kingbattleutil'
local kbrank = require 'gamesys.kingbattlerank'
local kbcmdata = require 'metadata'.kingbattlecommon[1]

local assert = assert
local pairs = pairs
local ipairs = ipairs
local randfunc = randfunc

local os = os
local math = math
local table = table

-- database collection
local collkb = require 'lnet'.env'db':getcol'kingbattle'
local collrole = require 'lnet'.env'db':getcol'role'
local collstone = require 'lnet'.env'db':getcol'stone'

-- constant 
local won_shift = 65536

local noncemax = 100000
local nonceoffset = math.floor(noncemax/1000)
local resultlimit = 5

local minplv = 10
local minscore = 1000


---------------------------------
--  utility functions
---------------------------------

local function gettargetplv(plv, won)
    local offset = 2
    if won < 70 then
        offset = math.floor(math.abs(won-1)/10) - 5
    end
    return math.max(minplv, plv+offset)
end

local function getnextscore(score)
	--TODO: 配置表
    return score
end

local function gennoncerange()
    local mid = math.random(noncemax)
    local r0 = mid - math.random(nonceoffset)
    local r1 = mid + math.random(nonceoffset)
    return math.max(0,r0), r1
end

local function genbotking()
    return math.random(1, 10) --TODO: 配置表
end

local function genbotformation(tid_king, botlv, nonce)
	local util = require 'gamesys.util'

	local awake = (botlv<=20 and 0 or 1)
	local quality = math.min(6, math.ceil(botlv/10))
	local skill_level = math.max(1, math.floor(botlv/3))

	local botlist = {
		-- king
		util.newbot(tid_king, botlv, awake, quality, skill_level)
	}

	-- heelers
	local rand = randfunc(nonce)
	local lookup = { [tid_king]=true }

	for n=1, 4 do
		local tid = rand(601, 649) -- 去重
		local bot = util.newbot(tid, botlv, awake, quality, skill_level)
		table.insert(botlist, bot)
	end

	return botlist
end

local function genbattlereward(key)
	local l = kbcmdata[key][1]
	local h = kbcmdata[key][2]
	return math.random(l, h)
end

---------------------------------
-- database helper functions 
---------------------------------

local cond_rolelist = {
	tid = { }
}

local fields_rolelist = {
	_id = 0, 
	tid = 1, level = 1, awake = 1,
    quality = 1, wisman = 1, sanctuary = 1,
    stone = 1, skill = 1,
}

local function loadrolelist(pid, rgnid, formation)
	cond_rolelist.pid = pid
	cond_rolelist.rgnid = rgnid
	cond_rolelist.tid['$in'] = bson.array(formation)
	
	local look = collrole:find(cond_rolelist, fields_rolelist):totable'tid'
	local list = {}

	for idx, tid in ipairs(formation) do
		local role = look[tid]
		list[idx] = role and role or table.empty
	end

	return list
end


local cond_stonelist = {
	sn = {}
}

local fields_stonelist = {
	_id = 0,
	pid = 0, rgnid = 0,
}

local function loadstonelist(pid, rgnid, rolelist)
	local snlist = {}
    for _, role in ipairs(rolelist) do
        for _, sn in ipairs(role.stone or table.empty) do
            if sn > 0 then
                table.insert(snlist, sn)
            end
        end
	end
	cond_stonelist.pid = pid
	cond_stonelist.rgnid = rgnid
	cond_stonelist.sn['$in'] = bson.array(snlist)
	return collstone:find(cond_stonelist, fields_stonelist):toarray()
end


local cond_enemies = {
	nonce = {},
	guard_ti = {},
	pid = {},
	['formation_def.1'] = { 
		['$exists'] = true 
	},
}

local fields_enemies = {
	_id = 0,
	pid = 1, rgnid = 1, plv = 1, nickname = 1,
    ['formation_def.1'] = 1,
}

local function searchenemies(pid, plv)
	local r0, r1 = gennoncerange()
	cond_enemies.plv = plv
	cond_enemies.nonce['$gte'] = r0
	cond_enemies.nonce['$lte'] = r1
	cond_enemies.guard_ti['$lt'] = os.time()
	cond_enemies.pid['$ne'] = pid

	local result = collkb:find(cond_enemies, fields_enemies):limit(resultlimit):toarray()

	-- 字段调整
	for _, enemy in ipairs(result) do
		enemy.tid = enemy.formation_def[1]
		enemy.formation_def = nil
	end

	-- 补机器人
	for n=1, resultlimit - #result do
        table.insert(result, {
			-- 机器人没有pid,rgnid
            plv = plv,
            nickname = '机器人' .. math.random(10000), --TODO: 配置表
            tid = genbotking(),
            -- 随机种子 用于生成详细阵营
            nonce = os.time() + math.random(noncemax)
        })
	end

	return result
end

local function updatenemy(pid, rgnid, point)
	-- 对方在线则跳过
	local shouldskip = location.get('user', pid, true)
	if shouldskip then
		return
	end

	-- setup condition
	local cond = {
		pid = pid,
		rgnid = rgnid,
		guard_ti = {
			['$lt'] = os.time()
		}
	}

	-- 追加条件 最低分值保护
	if point < 0 then
		cond.score = {
			['$gt'] = { minscore - point }
		}
	end

	-- fields selector
	local fields = {
		_id = 0,
		score = 1
	}

	-- setup update content
	local update = {
		['$inc'] = { score = point  }
	}

	-- 追加操作 保护时间
	if point < 0 then
		update['$set'] = { guard_ti = os.time()+kbcmdata.guard_time }
	end

	return collkb:find_modify(cond, fields, update)
end


---------------------------------
-- module interface 
---------------------------------

local function reset(model)
    local now = os.time()
    local kb = model.kingbattle

	-- TODO: 玩家等级验证
	local lastscore = kb.score

    if now > kb.finish_ti then
        kb.finish_ti = now + 5*60 --TODO: kbutil.season()
        kb.guard_ti = 0
        kb.refresh_ti = -1
        kb.nonce = math.random(noncemax)
        kb.won = 0
        kb.score = getnextscore(lastscore or minscore)
        kb.enemies = nil

		-- send mail
		-- 避免在初始赛季发放奖励...
		if lastscore then
		end
    end

    return kb
end

local function search(model)
    local kb = model.kingbattle

	-- 获取胜利计数
	local won_count = math.floor(kb.won/won_shift)

    -- 搜索超时验证
	-- TODO: 玩家等级验证
    if not kb:is_refresh_timeout() and won_count < resultlimit then 
		return 
	end

    -- 计算浮动后的目标玩家等级
	local plv = gettargetplv(kb.plv, won_count)

	-- 读取匹配结果
	-- *允许跨区服匹配, 否则应带上rgnid
	local result = searchenemies(model.pid, plv)

	-- 更新kb对象
	kb.won = 0
	kb.enemies = result
	
	if won_count < resultlimit then
		kb:update_refresh_timeout()
	end

    return kb.refresh_ti, result
end

local function getformation(model, index)
    local enemy = model.kingbattle.enemies[index]
	assert(not enemy.beat, 'this enemy has been beaten')

	-- remeber index for further using
	model:setvar('kingbattleindex', index)

	local rolelist
	local stonelist

    if enemy.pid then
        local cond = {
            pid = enemy.pid,
            rgnid = enemy.rgnid,
        }
        local fields = {
			_id = 0,
            formation_def = 1
		}

		local formation = collkb:find_one(cond, fields).formation_def
		rolelist = loadrolelist(enemy.pid, enemy.rgnid, formation)
		stonelist = loadstonelist(enemy.pid, enemy.rgnid, rolelist)

	else
		rolelist = genbotformation(enemy.tid, enemy.plv, enemy.nonce)
	end

	return rolelist, stonelist
end

local function beginbattle(model, index)
end

local function endbattle(model, won)
	local index = model:delvar'kingbattleindex'
	assert(index, 'battle context is error')

	local kb = model.kingbattle

	-- 分值变化
	-- 1. 挑战成功 自己+ 对方-
	-- 2. 挑战失败 自己0 对方+
	local enemy = kb.enemies[index]
	local point = 10 + enemy.plv - kb.plv

	--更新防守方(真人且同区服)
	if enemy.rgnid == model.rgnid then

		local point_defencer = won and -point or point

		-- 回写成功 
		-- 1. 更新排行
		-- 2. 追加防守记录
		local r = updatenemy(enemy.pid, enemy.rgnid, point_defencer)
		if r then
			 kbrank.update(rgnid, r.score, r.score + point_defencer)

			-- 追加防守记录
			-- addguradrecord(pid, rgnid, kb.formation_atk[1], kb.nickname, point_defencer)
		end
	end

	-- 更新进攻方
	local r = {}

	if won then
		-- 分值及榜单更新
		local oldscore, curscore = kb:update_score(point)
		kbrank.update(model.rgnid, oldscore, curscore)

		-- 更新beat标记 不可重复挑战
		enemy.beat = true

		-- 胜场次数
		kb.won = kb.won + won_shift

		-- 奖励
		r.coin = genbattlereward'battle_reward_coin'
		r.energy = genbattlereward'battle_reward_energy'
		r.player_exp = kbcmdata.player_exp
		r.role_exp = kbcmdata.role_exp

		model.bag:addcoin('kingbattle', r.coin)
		model.base:addenergy(r.energy)
		model.base:addplayerexp(r.player_exp)

		for _, tid in ipairs(kb.formation_atk) do
			local role = model.role[tid]
			if role then
				role:addlevelexp(r.role_exp)
			end
		end
	end

	-- generate video

	-- 返回结果给客户端
	r.score = kb.score
	r.score_incre = won and point or 0

	return r
end



return {
    reset = reset,
    search = search,
    getformation = getformation,
    beginbattle = beginbattle,
    endbattle = endbattle,
}
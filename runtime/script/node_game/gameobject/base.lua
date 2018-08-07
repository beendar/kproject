local time = os.time
local floor = math.floor
local min = math.min
local assert = assert
local setmetatable = setmetatable
local difftime = difftime

local metadata = require 'metadata'
local plvdata = metadata.playerlevelattr
local gcdata  = metadata.gamecommon[1]
local acctdata = metadata.accountcommon[1]

local TOLERANCE = 10

---@class base
---@field _data tBase
local interface = {}

function interface:addenergy(inc)
    self:energyup()
    self.energy = self.energy + inc
    return self.energy
end

function interface:addplayerexp(total) 
    total = total + self.plv_exp
    
    local expdata = acctdata.exp_account
	local maxlevel = #expdata
	local level  = self.plv + 1

	while expdata[level] and total >= expdata[level] and level < maxlevel do
		total = total - expdata[level]
		level  = level + 1
    end
    
    self.plv = level
    self.plv_exp = total

    self.Model.kingbattle.plv = level
end

function interface:addjungleexp(inc)
    self.jungle_exp = self.jungle_exp + inc
end

function interface:acceptjungle()
    self.jungle_money_times = self.jungle_money_times + 1
end

function interface:openkagutsu( tid )
    self.kagutsu_open = math.max(self.kagutsu_open, tid)
end

-- 恢复体力
---@private
function interface:energyup()
    local maxval = plvdata[self.plv].energyMax
    if self.energy < maxval then
        local elapsed = time() + TOLERANCE - self.energy_ti
        local point = floor(elapsed / gcdata.energyTime)
        self.energy = min(self.energy + point, maxval)
        self.energy_ti = self.energy_ti + point * gcdata.energyTime
    else
        self.energy_ti = time()
    end
    return self.energy
end

-- 扣减体力
function interface:energydown(cost)
    local left = self.energy - cost
    assert(left >=0 , 'energy is less than zero after consuming')
    self.energy = left
end

-- 设置昵称
function interface:setnickname(nn)
    self.nickname = nn
    self.Model.kingbattle.nickname = nn
end

-- 重置超时相关的属性
function interface:reset()
    local now = time() 
    local nextzero = now + difftime(0, 0, 0)
    -- 送好友体力
    if now >= self.present_ap_ti then
        self.present_ap_count = 0
        self.present_ap_ti = nextzero
    end
    -- 加入公会申请
    if now >= self.clan_req_ti then
        self.clan_req_count = 0
        self.clan_req_ti = nextzero
    end
    -- 每日挑战重置次数
    if now >= self.daily_challenge_ti then
        self.daily_challenge = {}
        self.daily_challenge_ti = nextzero
    end
    -- TODO: delete 版署需求
    if now >= self.extract_ti then
        self.extract_chance = 20
        self.extract_ti = nextzero
    end
end

function interface:check_clan_req_count()
    return (self.clan_req_count < gcdata.dailyApply)
end

function interface:inc_clan_req_count()
    self.clan_req_count = self.clan_req_count + 1
end

-- 递增好友赠送体力次数
function interface:inc_present_ap_count()
    self.present_ap_count = self.present_ap_count + 1
    return (self.present_ap_count <= gcdata.present_ap_max)
end

-- 好友列表是否满
function interface:friendfull()
    return (self.sysfriendn >= gcdata.friends_max)
end

function interface:incfriendn(inc)
    local n = self.sysfriendn + inc
    self.sysfriendn = n
end

-- 存档摘要信息
function interface:summary(type)
    local retval = {
        pid = self.pid,
        rgnid = self.rgnid,
        nickname = self.nickname,
        headid = self.headid,
        plv = self.plv,
        clanid = self.clanid,
    }
    if type == 'clan' then
        retval.online = self.online
        retval.offline = self.offline
        retval.sign = self.sign
        retval.mask = self.mask
    end
    return retval
end

-- 体力/金币购买
--!@param: type
--      'gold', 'energy'
function interface:dailybuy(type)
    local now = time()
    local field_buy = type .. '_buy'
    local field_ti = type..'_buy_ti'
    -- try重置时间及次数
    if now >= self[field_ti] then
        self[field_ti] = now + difftime(0,0,0)
        self[field_buy] = 0
    end
    -- 更新/检测次数
    local buy = self[field_buy] + 1
    self[field_buy] = buy
    assert(buy <= gcdata[type..'Buy'], 'buying count is used out')
    -- 扣减钻石
    local incr = gcdata[type..'Number']
    local cost = gcdata[type..'Price'][buy]
    local bag = self.Model.bag
    bag:addcoin('rmb', -cost)
    -- 分类处理
    local next_ti = self[field_ti]
    if type == 'gold' then
        return bag:addcoin('gold', incr), next_ti 
    end
    return self:addenergy(incr), next_ti 
end


return interface
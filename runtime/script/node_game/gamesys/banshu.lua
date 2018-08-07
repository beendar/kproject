local lnet = require 'lnet'

local account = require 'pub.account'
local archivesys = require 'gamesys.archive'
local dungeonsys = require 'gamesys.dungeon'

local pairs = pairs
local assert = assert


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

local config = {
    -- 高级
    [1] = {
        role_star = 3,
        role_level = 30,
        skill_level = 3,
        stone_star = 3,
        item_count = 999,
        rmb = 1000000,
        gold = 10000000,
    },

    --中级
    [2] = {
        role_star = 2,
        role_level = 20,
        skill_level = 2,
        stone_star = 2,
        item_count = 500,
        rmb = 500000,
        gold = 5000000,
    },

    -- 初级
    [3] = {
        role_star = 1,
        role_level = 10,
        skill_level = 1,
        stone_star = 1,
        item_count = 100,
        rmb = 10000,
        gold = 100000,
    },
}

local collections = {
    bag = 1,
    base = 1,
    chapter = 1,
    clanbase = 1,
    clanmember = 1,
    committal = 1,
    friend = 1,
    island = 1,
    jungle = 1,
    kagutsu = 1,
    kingbattle = 1,
    mallrecord = 1,
    mission = 1,
    pmethod = 1,
    role = 1,
    stone = 1,
    sysmail = 1,
    usermail = 1,
}


local function coinid(name)
    return coinToId[name]
end


local banshu = {}

function banshu.dropall()
    local db = lnet.env'db'
    for name in pairs(collections) do
        db:getcol(name):remove{}
    end
    lnet.sleep(2)
    print('all collections dropped~~~~')
end

function banshu.reset(token, rgnid, index)
    local r = account.get(token, true)
    if not r then
        local errmsg = string.format('account of token %s is not exist', token)
        error(errmsg)
    end

    assert(rgnid == 1, 'region id is invalid')
    assert(index>=1 and index<=3, 'config index is invalid')

    local archive = archivesys.load(r.pid, rgnid)
    local conf = config[index]

    -- 角色
    for tid in pairs(archive.role) do
        local role = archive.role[tid]
        role.quality = conf.role_star
        role.level = conf.role_level
        role.skill[1].level = conf.skill_level
        role.skill[2].level = conf.skill_level
        role.skill[3].level = conf.skill_level
    end

    -- 魂石
    for sn in pairs(archive.stone) do
        local stone = archive.stone[sn]
        stone.star = conf.stone_star
    end

    -- 物品
    for tid in pairs(archive.bag) do
        local item = archive.bag[tid] 
        item.count = conf.item_count
    end

    -- 货币
    archive.bag[coinid'rmb'].count = conf.rmb
    archive.bag[coinid'gold'].count = conf.gold

    -- 基本信息
    archive.base.nickname = '测试用户' .. (tonumber(r.pid)%10)

    -- 落地
    for _, data in pairs(archive) do
        data:save()
    end

    -- 主线关卡(特殊)
    dungeonsys.openall(r.pid, rgnid)

    local msg = string.format('archive of token [%s] reset', token)
    print(msg)
end

function banshu.batch_reset(tokenlist, rgnid)
    for token, idx in pairs(tokenlist) do
        banshu.reset(token, rgnid or 1, idx)
    end
end



return banshu
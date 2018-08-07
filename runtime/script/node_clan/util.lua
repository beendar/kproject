local genid = require 'pub.genid'
local location = require 'pub.location'
local cluster = require 'cluster.slave'

local T_BASE = 'clanbase'
local T_MEMBER = 'clanmember'

local mongo = require'lnet'.env'db'
local proxy = require 'db.mgo.proxy'(mongo)
proxy:addspec(T_BASE)
proxy:addspec(T_MEMBER, 'pid', 's')


local function newmember(clanid, pid, role)
	return {
		clanid = clanid,
        pid = pid,
        role = role,
        jointime = os.time(),
        score = 0,
        medal = 0,
    }
end

local function newclan(masterid, rgnid, name, sign, icon)
    local clanid = genid.next'clan' 

    local base = {
        clanid = clanid,
        rgnid = rgnid,
        masterid = masterid,
        name = name,
        sign = sign,
        icon = icon,
        level = 1,
        gold = 99999999,
        medal = 0,
        score = 0,
		reqs = 0,
		mbrs = 1,
    }

    local member = {
        [masterid] = newmember(clanid, masterid, 4) -- 4 role_master, see clan.lua
    }

    proxy:insert(T_BASE, base)
    proxy:insert(T_MEMBER, member)

    return clanid
end

local function loadclan(clanid)
    -- 必须按下列顺序执行

	-- 1. 从db加载公会数据并创建实例
    local cond = { clanid=clanid }
    
    -- 加载基本信息
    -- 若公会数据不存在则返回空地址
    local base = proxy:load(T_BASE, cond, {_id=0})
    if not base then
        return {}
    end

    -- 加载成员列表
    local member = proxy:load(T_MEMBER, cond, {_id=0, clanid=0})
    
    -- 2. 更新实例位置
	local addr,handle = cluster.gensul()
    local ok, clanpos = location.setnx('clan', clanid, addr, handle)
    
    -- 更新位置成功 则创建/启动公会实例
    -- 否则直接使用其他节点创建的实例地址
    if ok then
        -- 更新成功 启动实例
        local inst = require 'clan'.wrap {
		    clanid = clanid,
		    addr   = addr,
		    handle = handle,
		    base   = proxy:bind(base, T_BASE, cond),
		    member = proxy:bind(member, T_MEMBER, cond),
        }

        inst:start()
    end

	return clanpos, ok
end

local function updateuserclanid(pid, rgnid, clanid)
    -- 尝试更新base集合中 对应玩家的clanid字段 原子操作

    local cond = {
        pid = pid,
        rgnid = rgnid,
        clanid = { ['$exists']=false }
    }

    local fields = { _id=0, rgnid=rgnid }

    local op = { clanid=clanid }

    -- 所以 存档基本信息/公会数据 需要放在同一个物理库...
    return mongo:getcol'base':find_modify(cond, fields, op)
end

local function cleanuserclanid(pid, rgnid)
    local cond = {
        pid = pid,
        rgnid = rgnid,
    }

    local op = {
        ['$unset']={ clanid=1 }
    }

    return mongo:getcol'base':update(cond, op)
end


return {
    newclan = newclan,
    newmember = newmember,
    loadclan = loadclan,
    updateuserclanid = updateuserclanid,
    cleanuserclanid = cleanuserclanid,
}
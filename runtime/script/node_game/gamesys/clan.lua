local bson = require 'database.mongo.bson'
local cluster = require 'cluster.slave'
local badword = require 'badword.core'
local location = require 'pub.location'
local nickname = require 'pub.nickname'

local pairs = pairs
local assert = assert

local colubase  = require'lnet'.env'db':getcol'base'
local colcbase  = require'lnet'.env'db':getcol'clanbase'
local colmember = require'lnet'.env'db':getcol'clanmember'

local CREATE_SUCCESS = 0
local CREATE_FAILED_NAME = 1
local CREATE_FAILED_SIGN = 2

local LOCATION = 'location.clan'

local function checkjoined(model)
    return assert(model.base.clanid, 'you have not been in a clan')
end

local function ensurelocation(clanid)
    -- 如果公会实例还未加载 则通知公会管理员加载 并返回实例地址
    local pos = location.get('clan', clanid, true)
    if not pos then
        local mngr = cluster.query'clan.manager'
        pos = cluster.call(mngr, 'lua', 'load', clanid)
    end
    return pos
end


local function create(model, name, sign, icon)
    local cost = 100 --TODO: 读取配置表
    local base = model.base
    local bag = model.bag

    assert(not base.clanid, 'you have been in a clan')
    assert(#name > 0, 'clan name should not be empty string')
    assert(bag:getcoin'rmb' >= cost, 'rmb is not enough')

    -- 个性签名检查
    if badword.find(sign) then
        return CREATE_FAILED_SIGN
    end

    -- 公会名检查
    if not nickname.check('clan', name) then
        return CREATE_FAILED_NAME
    end

    -- 创建一个公会 并更新用户存档
    local mngr = cluster.query'clan.manager'
    base.clanid = cluster.call(mngr, 'lua', 'create', base.pid, base.rgnid, name, sign, icon)
    base.clanmaster = true

    -- 扣减rmb
    bag:addcoin('rmb', -cost)

    -- 重置工会币
    bag:setcoin('clan', 0)

    return CREATE_SUCCESS
end

local function login(model)
    -- 确定公会实例的位置
    local pos = ensurelocation(checkjoined(model))
    model:setvar(LOCATION, pos)

    -- 获取公会基本信息
    return cluster.call(pos, 'lua', 'baseinfo')
end

local function requestjoin(model, clanid)
    local base = model.base
    assert(not base.clanid, 'you have been in a clan')
    base:reset()
    assert(base:check_clan_req_count(), 'clan request count is used out')
    model.bag:setcoin('clan', 0)
    local pos = ensurelocation(clanid)
    local ok = cluster.call(pos, 'lua', 'requestjoin', base:summary'clan')
    if ok then
        base:inc_clan_req_count()
    end
    return ok
end

local function handlejoin(model, dst, ok)
    checkjoined(model)
    local pos = model:getvar(LOCATION)
    cluster.send(pos, 'lua', 'handlejoin', model.pid, dst, ok)
end

local function kick(model, dst)
    checkjoined(model)
    local pos = model:getvar(LOCATION)
    cluster.send(pos, 'lua', 'kick', model.pid, dst)
end

local function quit(model)
    checkjoined(model)
    local pos = model:getvar(LOCATION)
    cluster.send(pos, 'lua', 'quit', model.pid)
    model.base.clanid = nil
    model.base.clanmaster = nil
    model.bag:setcoin('clan', 0)
end

local function loadmember(clanid, rgnid, page)
    -- 加载列表
    local cond = { clanid=clanid }
    local fields = { _id=0, clanid=0 }
    local list = colmember:find(cond, fields):totable'pid'

    -- 根据列表加载详情
    local cond = { 
        rgnid = rgnid,
        pid = { ['$in']=bson.array(table.keys(list)) }
    }

    local fields = {
        _id = 0,
        pid = 1, nickname = 1, headid = 1, plv = 1,
        sign = 1, online = 1, offline = 1, mask = 1
    }

    local detail = colubase:find(cond, fields):totable'pid'
    for pid,member in pairs(list) do
        local base = detail[pid]
        base.pid = nil
        member.base = base
    end

    return list
end

local function searchbyid(clanid)
    local cond = {clanid=clanid}
    local fields = {_id=0}
    return colcbase:find_one(cond, fields)
end

local function searchbyname(clanname)
    local cond = {
        name = bson.regex{clanname, 'i'},
        mbrs = {['$gt']=0}
    }
    local fields = {_id=0}
    return colcbase:find(cond, fields):limit(10):toarray()
end

local function retrievehistoryevent(model, type)
    checkjoined(model)
    assert(type == 0 or type == 1, 'invalid request type')
    local pos = model:getvar'chatroom.clan' -- see gamesys/chat.lua
    return cluster.call(pos, 'lua', '.RetrieveHistoryEvent', type, model.base.offline)
end

local function setrole(model, dst, role)
    checkjoined(model)
    local pos = model:getvar(LOCATION)
    return cluster.call(pos, 'lua', 'setrole', model.pid, dst, role)
end

local function modifybaseinfo(model, field, value)
    checkjoined(model)
    assert(field == 'name' or field == 'sign' or field == 'icon', 'invalid field')

    -- 检查公会名
    if field == 'name' and not nickname.check('clan', value) then
        return CREATE_FAILED_NAME
    end

    -- 检查签名
    if field == 'sign' and badword.find(value) then
        return CREATE_FAILED_SIGN 
    end

    -- 转发到公会实例做后续处理
    local pos = model:getvar(LOCATION)
    cluster.send(pos, 'lua', 'modifybaseinfo', model.pid, field, value)

    return CREATE_SUCCESS
end

local function upgrade(model)
    checkjoined(model)
    local pos = model:getvar(LOCATION)
    return cluster.call(pos, 'lua', 'upgrade', model.pid)
end


return {
    create = create,
    login = login,
    requestjoin = requestjoin,
    handlejoin = handlejoin,
    kick = kick,
    quit = quit,
    loadmember = loadmember,
    searchbyid = searchbyid,
    searchbyname = searchbyname,
    retrievehistoryevent = retrievehistoryevent,
    setrole = setrole,
    modifybaseinfo = modifybaseinfo,
    upgrade = upgrade,
}
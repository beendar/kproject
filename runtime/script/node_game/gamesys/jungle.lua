local mongo = require 'lnet'.env'db'
local metadata = require'metadata'
local jungle_conf = metadata.jungle
local lvconf = metadata.jungleLevel
local jungle4type = metadata.jungle4type
local bson = require 'database.mongo.bson'
local mailsender = require'gamesys.mailsender'
local clansys = require'gamesys.clan'
local colmember = require'lnet'.env'db':getcol'clanmember'

local function hasfriend( u )
    for k,v in pairs(u.model.friend) do
        return true
    end
end

local function inclan( u )
    return u.model.base.clanid
end

local function acceptedlist(u)
    if not hasfriend(u) and not inclan(u) then
        return {}
    end
    local accepted_cond = {}
    accepted_cond['$or'] = bson.array{
        {
            status = 3, 
            got_money = false
        },
        {
            expire = {
                ['$gt']=os.time()
            }
        }
    }

    accepted_cond.accept = u.pid
    accepted_cond.rgnid = u.rgnid
    return mongo:getcol'jungle':find(accepted_cond, {_id=0}):limit(20):toarray()
end

local jungle_return_limit = 20
local function publishedlist(u)
    local published_cond = {
        status = 1,
        rgnid = u.rgnid
    }
    published_cond.expire = {['$gt']=os.time()}

    local lst = table.keys(u.model.friend)

    published_cond.pid = {['$in']= bson.array(lst)}
    local ret = {}

    if hasfriend(u) then
        ret = mongo:getcol'jungle':find(published_cond, {_id=0}):limit(jungle_return_limit):toarray()
    end

    if inclan(u) and #ret < 20 then
        local clanid = u.model.base.clanid
        if clanid ~= nil then
            table.insert( lst, u.pid )
            local cond = {
                clanid = clanid,
                pid = {['$nin']= bson.array(lst)}
            }
            local fields = {
                _id = 0,
                pid = 1,
            }
            local member = table.keys(colmember:find(cond, fields):totable'pid')
            published_cond.pid = {['$in']= bson.array(member)}
            local mret = mongo:getcol'jungle':find(published_cond, {_id=0}):limit(jungle_return_limit - #ret):toarray()
            for _,v in pairs(mret) do
                table.insert( ret, v )
            end
        end
    end

    return ret
end



local function accept( pid, rgnid, sn, accept )
    local accept_cond = {
        status = 1
    }
    accept_cond.expire = {['$gt']=os.time()}
    accept_cond.sn = sn
    accept_cond.pid = pid
    accept_cond.rgnid = rgnid
    return mongo:getcol'jungle':find_modify(accept_cond,{_id=0},{accept=accept,expire=os.time()+7200,status=2},true,false)
end



local function update( pid, rgnid, sn, val )
    local update_cond = {}
    update_cond.sn = sn
    update_cond.pid = pid
    update_cond.rgnid = rgnid
    local tmp = mongo:getcol'jungle':find_modify(update_cond,{_id=0},{['$inc']={current=val}},true,false)
    if not tmp then
        return nil
    end
    if tmp.status < 3 and tmp.current >= jungle_conf[tmp.tid].target[1].count then
        tmp = mongo:getcol'jungle':find_modify(update_cond,{_id=0},{status=3},true,false)
    end
    return tmp
end


local function reward( pid, rgnid, sn, upid )
    local reward_cond = {}
    reward_cond.sn = sn
    reward_cond.pid = pid
    reward_cond.rgnid = rgnid
    reward_cond.status = 3
    local op = {}
    if pid == upid then
        reward_cond.got_reward = false
        reward_cond.got_money = nil
        op.got_reward = true
    else
        reward_cond.got_reward = nil
        reward_cond.got_money = false
        op.got_money = true
    end
    
    return mongo:getcol'jungle':find_modify(reward_cond,{_id=0},op,true,false)
end

local function get_reward( tid )
    return jungle_conf[tid].reward
end

local function is_daily( tid )
    return jungle_conf[tid].jtype == 1
end

local function get_money( tid )
    return jungle_conf[tid].money
end


--最大个数
local base_conf = {
    [1] = 3,    --普通
    [2] = 3,    --精英
    [3] = 20,   --悬赏
}

local function new_jungle( pid, rgnid, tid, sn )
    return {
        sn = sn,
        tid = tid,
        current = 0,
        pid = pid,
        rgnid = rgnid,
        accept = '',
        status = 0,
        expire = 0,
        got_reward = false,
        got_money = false,
    }
end

local function gentid( tp, lv, exist )
    lv = lv <= 0 and 1 or lv
    local confs = jungle4type[tp][lv]
    for i=1,10 do
        local idx = math.random( 1,#confs )
        if not exist[confs[idx].tid] then
            exist[confs[idx].tid] = true
            return confs[idx].tid
        end
    end
end

local function leveldown( u, tid )
    local exits = {}
    for _,v in pairs(u.model.jungle) do
        exits[v.tid] = true
    end
    local conf = jungle_conf[tid]
    local try_tid = gentid(conf.jtype, conf.level - 1, exits)
    if try_tid then
        return {
            tid = try_tid
        }
    end
end

local function refresh( u )
    local model = u.model
    local base = model.base
    local now = os.time()

    if base.jungle_ti < now then
        --[[
            Lua的每周第一天是星期天
        ]]
        local elite_new = tonumber(os.date('%w')) == 1
        if elite_new then
            base.jungle_finish_count = 0
        else
            if now - base.jungle_ti > 604800 then
                elite_new = true
            end
        end

        for k,v in pairs(model.jungle) do
            if v.status == 3 then
                if not v.got_money or not v.got_reward then
                    --奖励自动发送
                    mailsender.p2self(u, '悬赏奖励', '刷新时，没领取的悬赏奖励，自动通过邮件发放。',{
                        gold = get_money(v.tid),
                        junglepoint = get_reward(v.tid),
                    })
                end
            end

            if jungle_conf[v.tid].jtype == 1 or elite_new then
                model.jungle[k] = nil
            end
        end

        local lv = 1
        for _,v in pairs(lvconf) do
            if base.jungle_exp >= v.jungle_exp then
                lv = v.jungle_lv
            else
                break
            end
        end

        local t = {}
        for jtype,count in pairs(base_conf) do
            --玩家发布的悬赏任务不需要创建
            if jtype == 2 and not elite_new or jtype == 3 then
                break
            end
            local tid_tb = {}
            for i=1,count do
                local tid = gentid(jtype,lv,tid_tb)
                if tid then
                    table.insert(t, new_jungle(u.pid, u.rgnid, tid, model:gensn()))
                end
            end
        end
        
        for k,v in pairs(t) do
            model.jungle[v.sn] = v
        end
        base.jungle_ti = now + difftime(0,0,0)
        base.jungle_money_times = 0
        return true, model.jungle, publishedlist(u), acceptedlist(u)
    else
        for k,v in pairs(model.jungle) do
            v = model.jungle[k]
            if v.status < 3 then
                if v.expire > 0 and v.expire < now then
                    if v.status == 1 then
                        --自动退赏金
                        mailsender.p2self(u, '悬赏赏金', '刷新时，过期的悬赏，自动退还赏金。',{
                            gold = jungle_conf[v.tid].money
                        })
                    end
                    v.status = 0
                    v.expire = 0
                end
            end
        end
    end
    return false, model.jungle, publishedlist(u), acceptedlist(u)
end




return {
    refresh = refresh,
    accept = accept,
    update = update,
    reward = reward,
    get_reward = get_reward,
    get_money = get_money,
    is_daily = is_daily,
    leveldown = leveldown,
}
--!@remark: lazyinit方式加载对应区服的榜单
local lnet = require 'lnet'
local collkb = lnet.env'db':getcol'kingbattle'
local collkbrank = lnet.env'db':getcol'kingbattlerank'

local kbutil = require 'gamesys.kingbattleutil'

local ipairs = ipairs
local os = os
local math = math
local table = table

local bucketstep = 20
local reloadduration = 300
local ranksize = 50
local pagesize = 10

local rankcache = {}


---------------------------------
--  utility functions
---------------------------------

local function tobucket(score)
    return math.floor(score/bucketstep)
end

local function loadregion(rgnid)
    local cond = {
        rgnid = rgnid
    }
    local fields = {
		_id = 0,
		pid = 1,
        nickname = 1,
        score = 1,
        formation_atk = 1,
    }
    local r = collkb:find(cond, fields):limit(ranksize):sort('score', -1):toarray()
    for idx, entry in ipairs(r) do
        entry.rank = idx
        entry.formation = entry.formation_atk
        entry.formation_atk = nil
    end
    return r
end

local cond = {}
local op = { 
    ['$inc'] = {
    } 
}

local function updaterank(rgnid, score, increment)
    cond.rgnid = rgnid
    cond.bucket = tobucket(score)
    cond.season = kbutil.season()
    op['$inc']['count'] = increment
    collkbrank:update(cond, op, 1)
end

local pipeline = {
    { ['$match'] = { bucket={} } },
    { ['$project'] = { _id=0, count=1 } },
    { ['$group'] = {_id=0, rank={['$sum']='$count'}} },
}

local function getroughrank(rgnid, score)
	local match = pipeline[1]['$match']
	match.rgnid = rgnid
	match.season = kbutil.season()
	match.bucket['$gte'] = tobucket(score)

	local r = collkbrank:aggregate(pipeline)
	if r.result[0] then
		return r.result[0].rank
	end
end

local function tryloadregion(rgnid)
	local now = os.time()
	local cache = rankcache[rgnid]

	if not cache or now > cache.ttl then
		cache = cache or {
			list = table.empty
		}

		rankcache[rgnid] = cache

		lnet.fork(function()
			cache.ttl = now + reloadduration -- point to next expire time
			cache.list = loadregion(rgnid) -- yield here
		end)
	end

	return cache.list
end

---------------------------------
-- module interface 
---------------------------------

local function getpage(pid, rgnid, score, page)
	local list = tryloadregion(rgnid)

	-- 切页
	local first = (page-1)*pagesize + 1
	local last = math.min(#list, page*pagesize)

	local r = {}
	for idx=first, last do
		table.insert(r, list[idx])
	end

	-- 排位
	local your_rank

	if page == 1 then
		-- 位于精确榜单? 
		for idx, entry in ipairs(list) do
			if entry.pid == pid then
				your_rank = idx
				break
			end
		end
		-- 否则获取粗略排位
		your_rank = your_rank or getroughrank(rgnid, score)
	end

	return r, your_rank
end

local function update(rgnid, oldscore, curscore)
    updaterank(rgnid, oldscore, -1)
    updaterank(rgnid, curscore,  1)
end


return {
    update = update,
    getpage = getpage,
}
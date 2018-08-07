local cluster   = require 'cluster.slave'
local util      = require 'gamesys.util'
local junglesys = require 'gamesys.jungle'
local location = require 'pub.location'


local HANDLER = {}

HANDLER['JungleRefresh'] = function( u, req )
	local new, t, ot, at = junglesys.refresh(u)
	t = table.clone(t)
	for _,v in pairs(ot) do
		if #at == 20 then
			break
		end
		table.insert(at,v)
	end

	for _,v in pairs(t) do
		v.pid = u.pid
	end

	if req.need_get or new then
		return {
			jungle = t,
			published = at
		}
	end
end

HANDLER['JungleLevelDown'] = function( u, req )
	local obj = u.model.jungle[req.sn]
	local jungle = junglesys.leveldown(u, obj.tid)
	if jungle then
		obj.tid = jungle.tid
		return {
			jungle = obj
		}
	end
end

HANDLER['JunglePublish'] = function( u, req )
	local obj = u.model.jungle[req.sn]
	return obj:publish()
end

HANDLER['JungleAccept'] = function( u, req )
	assert(u.model.base.jungle_money_times < 3,'money jungle times is not enough')
	local jungle = junglesys.accept(req.pid, u.rgnid, req.sn, u.pid)
	if not jungle then
		return {
			ok = false
		}
	end
	local base = u.model.base
	base:acceptjungle()

	local position = location.get('user', req.pid)
	cluster.send(position, 'lua', '.JungleAccept', jungle)
	return {
		ok = true,
		jungle = jungle
	}
end

HANDLER['.JungleAccept'] = function( u, req )
	u.model.jungle[req.sn]:doaccept(req)
end

HANDLER['JungleUpdate'] = function( u, req )
	local jungle = junglesys.update(req.pid, u.rgnid, req.sn, req.add)
	if not jungle then
		return {
			ok = false
		}
	end

	local position = location.get('user', req.pid)
	cluster.send(position, 'lua', '.JungleUpdate', jungle)
	return {
		ok = true,
		jungle = jungle
	}
end

HANDLER['.JungleUpdate'] = function( u, req )
	u.model.jungle[req.sn]:update(req)
end

HANDLER['JungleReward'] = function( u, req )
	local jungle = junglesys.reward(req.pid, u.rgnid, req.sn, u.pid)
	if not jungle then
		return {
			ok = false
		}
	end

	local ret = {
		ok = true
	}

	local base = u.model.base
	local bag = u.model.bag

	if req.pid == u.pid then
		ret.reward = junglesys.get_reward(jungle.tid)
		bag:addcoin('jungle', ret.reward)
		base:addjungleexp(ret.reward)
		if junglesys.is_daily(jungle.tid) then
			base.jungle_finish_count = base.jungle_finish_count + 1
		end
	else
		ret.money = junglesys.get_money(jungle.tid)
		bag:addcoin('gold', ret.money)
		base.jungle_money_times = base.jungle_money_times + 1
	end

	local position = location.get('user', req.pid)
	cluster.send(position, 'lua', '.JungleReward', jungle)
	return ret
end

HANDLER['.JungleReward'] = function( u, req )
	u.model.jungle[req.sn]:reward(req)
end



return HANDLER
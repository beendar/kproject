local util = require 'gamesys.util'

local assert = assert


local HANDLER = {}

HANDLER['CommittalBegin'] = function(u, req)
	assert(util.check_committal(req.tid),'tid is error')
	local obj = u.model.committal[req.tid]
	if not obj then
		u.model.committal[req.tid] = util.newcommittal(u.pid, u.rgnid, req.tid, u.model:gensn())
		u.model:save()
		obj = u.model.committal[req.tid]
	end

	local status, finish = obj:start(req.characters)
	return {
		tid = req.tid,
		status = status,
		finish = finish
	}
end

HANDLER['CommittalEnd'] = function(u, req)
	print('CommittalEnd')
	local obj = u.model.committal[req.tid]
	assert(obj,'not find this committal tid = '..req.tid)
	local status, tid, times, chance = obj:dofinish(req.finish)
	return {
		tid = tid,
		tid = req.tid,
		status = status,
		big = false,
		times = times,
		chance = chance
	}
end



return HANDLER
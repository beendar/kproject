local util = require 'gamesys.util'

local assert = assert


local HANDLER = {}

HANDLER['KagutsuRefresh'] = function(u, req)
	return {
		kagutsu = u.model.kagutsu:raw()
	}
end

HANDLER['KagutsuSelect'] = function(u, req)
	return {
		kagutsu = u.model.kagutsu:new(req.tid)
	}
end

HANDLER['KagutsuBattleEnd'] = function(u, req)
	return {
		kagutsu = u.model.kagutsu:battle(req)
	}
end

HANDLER['KagutsuReward'] = function(u, req)
	return {
		kagutsu = u.model.kagutsu:reward(req.tid)
	}
end

HANDLER['KagutsuReset'] = function(u, req)
	return {
		kagutsu = u.model.kagutsu:reset()
	}
end

return HANDLER
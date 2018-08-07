local util = require 'gamesys.util'

local itemsys = require 'gamesys.item'


local HANDLER = {}

HANDLER['UseItem'] = function(u, req)
	local model = u.model
	model.bag:removeitem(req.items)
	return itemsys.use(model, req)
end

HANDLER['SellItem'] = function(u, req)
	local bag = u.model.bag
    local gold = 0
	gold = gold + bag:sellitem(req.items)
	gold = gold + bag:sellstone(req.stones)
    return { gold=gold }
end

HANDLER['InsertStone'] = function(u, req)
	local model = u.model
	local role  = model.role[req.role]
	role:insertstone(req.position, req.stone, model)
end

HANDLER['UpgradeSanctuary'] = function(u, req)
	local tid = req.role
	local index = req.index
	u.model.role[tid]:upgradesanctuary(index)
end


return HANDLER
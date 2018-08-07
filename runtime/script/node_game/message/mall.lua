local mallsys = require 'gamesys.mall'


local HANDLER = {}

HANDLER['MallRetrieveList'] = function(u, req)
    mallsys.checkshopid(req.id)

    local model = u.model
    local list, refresh_ti = mallsys.genlist(model, req.id, req.forcely) 

    return {
        list = list,
        bought = model.mallrecord:getfield(req.id, 'bought'),
        refresh_ti = refresh_ti
    }
end

HANDLER['MallBuy'] = function(u, req)
    return mallsys.buy(u.model, req.shopid, req.goodsid)
end


return HANDLER
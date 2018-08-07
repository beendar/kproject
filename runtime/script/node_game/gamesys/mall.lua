local metadata = require 'metadata'
local itemsys = require 'gamesys.item'

local math = math
local assert = assert
local errorfa = errorfa

local SHOPS = {}

local malldata = metadata.mall
local goodsdata = metadata.goods

local mallsys = {}

function mallsys.checkshopid(id)
    errorfa(SHOPS[id], 'invalid shop id %d', id)
end

function mallsys.genlist(model, id, forcely)
    local shop = SHOPS[id]
    if not forcely then
        return shop:genlist(model)
    end

    local coin = malldata[id].refreshCostType
    local price = malldata[id].refreshCost

    -- 代币检查
    local bag = model.bag
    assert(bag:getcoin(coin) >= price, 'coin is not enough for refresh goods list')

    -- 扣减代币
    bag:addcoin(coin, -price)

    -- 强制生成新列表
    return shop:genlist(model, true)
end

function mallsys.buy(model, id, tid)
    local shop = SHOPS[id]
    assert(shop:checkgoodsid(tid, model), 'invalid goodsid in this shop')

    local bag = model.bag
    local record = model.mallrecord

    -- 钱够不够
    local conf = goodsdata[tid]
    local realprice = math.floor(conf.price * conf.discount / 100)
    assert(realprice <= bag:getcoin(conf.moneyType) , 'coin is not enough for this goods')

    -- 库存够不够
    local bcheckstock = conf.stock > 0
    local stockok = not bcheckstock or record:checkstock(id, tid, conf.stock)
    assert(stockok, 'none stock for this goods')

    -- 处理商品包含的物品列表
    -- (月卡类需要特殊处理)
    local r = itemsys.gen(conf.include, model)
    itemsys.apply(r, model)

    -- 更新代币
    bag:addcoin(conf.moneyType, -realprice)

    -- 更新购买记录
    if bcheckstock then
        record:updatestock(id, tid)
    end

    return r
end

function mallsys.startup()
    for id,type in ipairs {
        'fixedpub',  -- 补给
        'randpriv',  -- 神秘
        'fixedpub',  -- 公会
        'fixedpub',  -- 雾
        'fixedpub',  -- 家具都
        'fixedpub',  -- 丛林
        'fixedpub',  -- 钻石
        'fixedpub',  -- 礼包
        'fixedpub',  -- 皮肤
        'fixedpub',  -- 活动
    } do
        local file = string.format('gamesys.shop.%s', type)
        SHOPS[id] = require(file)(id)
    end
end


return mallsys
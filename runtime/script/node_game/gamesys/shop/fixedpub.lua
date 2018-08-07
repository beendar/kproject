local os = os
local malldata = require 'metadata'.mall

mt = mt or {}
mt.__index = mt


function mt:genlist(model)
    self:update()

    local id = self.id
    local ti = self.refresh_ti

    -- 刷新库存的操作 实现为重置用户在该商店的购买记录
    -- 用户每次购买后 购买记录是否更新 取决于商品自身的stock属性 而非商店
    model.mallrecord:tryrefresh(id, ti or 0)

    local conf = malldata[id]
    return conf.goodsID, ti
end

function mt:checkgoodsid(tid, model)
    local list = self:genlist(model)
    return list[tid]
end

function mt:init()
    -- 固定列表的商店 分支仅为是否刷新库存
    local conf = malldata[self.id]
    -- 库存刷新周期大于0的才赋予刷新超时字段
    self.refresh_intv = conf.refreshcycle * 3600
    if self.refresh_intv > 0 then
        self.refresh_ti = os.time() + self.refresh_intv
    end
    return self
end

function mt:update()
    local ti = self.refresh_ti
    if ti and os.time() > ti then
        self.refresh_ti = os.time() + self.refresh_intv
    end
end


return function(id)
    return setmetatable({id=id}, mt):init()
end
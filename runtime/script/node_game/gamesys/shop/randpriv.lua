local os = os
local util = require 'gamesys.shop.util'

local malldata = require 'metadata'.mall

mt = mt or {}
mt.__index = mt


function mt:genlist(model, forcely)
    local id = self.id
    local token = self.token

    local record = model.mallrecord
    local ti = record:getfield(id, 'refresh_ti')

    if ti > 0 and not model:getvar(token) then
        model:setvar(token, util.genrandlist(id,ti))
    end

    if os.time() > ti or forcely then
        ti = util.gennextrefresh(id)
        record:tryrefresh(id, ti)
        model:setvar(token, util.genrandlist(id,ti))
    end
    
    return model:getvar(token), ti
end

function mt:checkgoodsid(tid, model)
    return model:getvar(self.token)[tid]
end

function mt:init()
    self.token = tostring(self)
    return self
end


return function(id)
    return setmetatable({id=id}, mt):init()
end
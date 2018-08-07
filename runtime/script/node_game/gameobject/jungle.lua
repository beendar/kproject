local conf = require'metadata'.jungle
---@class jungle
local interface = {}


function interface:publish()
    self.status = 1
    self.expire = os.time() + 2 * 3600
    self.current = 0
    self.Model.bag:addcoin('gold', -conf[self.tid].money_aftertax)

    return {
        status = self.status,
        expire = self.expire,
    }
end

function interface:update( jungle )
    self.Pure.current = jungle.current
    self.Pure.status = jungle.status
end

function interface:reward( jungle )
    self.Pure.got_reward = jungle.got_reward
    self.Pure.got_money = jungle.got_money
end

function interface:doaccept( jungle )
    self.Pure.accept = jungle.accept
    self.Pure.expire = jungle.expire
    self.Pure.status = jungle.status
end


return interface
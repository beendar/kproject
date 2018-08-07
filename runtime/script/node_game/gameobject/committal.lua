local metadata    = require 'metadata'
local conf = metadata.committal
local iconf = metadata.item
local idle = 0
local underway = 1
local finish = 2

local item = require'gamesys.item'

---@class committal
local interface = {}

function interface:start(characters)
    --assert(self.status == idle, 'committal status not is idle')
    self.status = underway
    self.characters = characters
    self.finish = os.time() + conf[self.tid].need_time
    local base = self.Model.base
    base:energyup()
    base:energydown(conf[self.tid].energyCost)

    return underway, self.finish
end

function interface:dofinish(finish)
    assert(self.status == underway,'committal status is error ...')
    local cconf = conf[self.tid]
    local chance
    if finish then
        assert(self.finish < os.time() + 5,'you are not finish...')
        assert(self.times > 0,'your times is not enough')
        self.times = self.times - 1

        local now = os.time()
        if self.expire < now then
            self.times = conf[self.tid].times
            self.expire = now + difftime(0, 0, 0)
        end

        if math.random() <= 0.6 then
            chance = true
            print('more exp')
        end
        
        local ret = item.gen(cconf.reward, self.Model)

        if chance then
            ret = item.gen(cconf.chance_reward, self.Model, ret)
        end
        item.apply(ret, self.Model, self.characters)
    end

    self.characters = {}
    self.status = idle
    self.finish = 0
    return idle, self.tid, self.times, chance
end

function interface:is_finish()
    return ((self.status == underway) and (self.finish < os.time()))
end


return interface
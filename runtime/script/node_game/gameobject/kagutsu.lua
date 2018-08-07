local metadata    = require 'metadata'

local kagutsu = metadata.kagutsuConfig
local awards  = metadata.awards

local item = require'gamesys.item'

---@class prototype
local interface = {}

function interface:new( tid )
    self.tid = tid
    self.line_pos = {}
    self.characters = {}
    self.got_reward = {}
    return self:raw()
end

function interface:raw()
    local ret = {
        tid = self.tid
    }

    if ret.tid then
        ret.characters = table.values(self.characters)
        ret.got_reward = table.keys(self.got_reward)
        ret.line_pos = table.keys(self.line_pos)
    end
    return ret
end

function interface:battle( req )
    self.line_pos[req.sid] = true

    local tid,mod = math.modf(req.sid/1000)
    if mod == 0 then
        self.Model.base:openkagutsu(tid+1)
    end
    
    local line
    local change = {}
    
    for _,v in pairs(req.characters) do
        line = v.line
        change[v.tid] = true

        local ol
        if mod == 0 then
            ol = self.characters[v.tid] and self.characters[v.tid].line
        end

        self.characters[v.tid] = {
            tid = v.tid,
            line = ol or v.line,
            hp = v.hp,
            idx = v.idx,
        }
    end

    for tid,v in pairs(self.characters) do
        v = self.characters[tid]
        if not change[tid] and v.line == line then
            v.idx = 0
        end
    end
    

    return self:raw()
end

function interface:reward( tid )
    assert(not self.got_reward[tid],'reward is not valid')
    self.got_reward[tid] = true

    local rid = kagutsu[self.tid].processReward[tid]
    local reward = awards[rid].dropList
    item.apply(item.gen(reward, self.Model), self.Model)

    return self:raw()
end

function interface:reset()
    self.Model.bag:incitem(6002, -20)

    for k,_ in pairs(self) do
        self[k] = nil
    end
    return self:raw()
end


return interface
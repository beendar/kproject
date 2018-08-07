local metadata = require'metadata'


---@class island
local interface = {}

function interface:find( tid )
    for i,v in ipairs(self.devices) do
        if v.tid == tid then
            return self.devices[i]
        end
    end
end

function interface:upgrade( tid )
    local device = self:find(tid)
    if not device then
        device = {
            tid = tid,
            level = 1,
            action = 1,
            expire = os.time() + 30,
            events = {}
        }
        self.devices[#self.devices + 1] = device
    else
        if device.action == 1 and device.expire <= os.time() then
            device.level = device.level + 1
            device.expire = 0
            device.action = 0
        elseif device.action == 0 then
            device.action = 1
            device.expire = os.time() + 30
        end
    end
    return device
end

return interface
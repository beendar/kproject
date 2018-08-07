local os = os
local pairs = pairs
local difftime = difftime

local committaldata = require 'metadata'.committal


local function refreshcommittal(model)
	local now = os.time()
    local coms = model.committal
    local dif = difftime(0, 0, 0)

    for k,v in pairs(coms) do
        v = coms[k]
        if v.status == 0 then
            if not v.expire or now > v.expire then
                v.times = committaldata[v.tid].times
                v.expire = now + dif
            end
        end
    end
end


local function online(model)
	model.base:reset()
    model.base:energyup()
    model.pmethod[1]:tryreset()

    refreshcommittal(model)
end

local function offline(model)
end


return {
    online = online,
    offline = offline
}
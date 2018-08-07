local lnet = require 'lnet'
local cluster = require 'cluster.slave'

local TURN = {}
local RESULT = {}

local arbitrated

local function vote(key, handle, duration)
    local turn = TURN[key] or 1
    TURN[key] = turn

    local r
    while not r do
        lnet.sleep(.5)
        r = cluster.call(arbitrated, 'lua', 'vote', key, handle, turn, duration or 1)
        print(string.format('%s - voting...... %d', key, os.time() % 10))
    end

    TURN[key] = r.turn
    RESULT[key] = r.winner and table.clone(r) or nil

    local msg = ('%s - %s in turn %d %s'):format(key, 
            r.winner and 'MASTER' or 'SLAVE',
            r.turn,
            r.winner and '' or ',MASTER is ' .. r.addr)

    print(msg)

    return r
end

local function result(key)
    local r
    while not r do
        r = cluster.call(arbitrated, 'lua', 'result', key)
        lnet.sleep(r and 0 or 1)
    end
    return r
end

local function startup()

    cluster.concern('arbitrated.offline', function()
        arbitrated = cluster.wait'arbitrated'
        for key, r in pairs(RESULT) do
            cluster.send(arbitrated, 'lua', 'maintain', key, r)
        end
    end)

    lnet.call'arbitrated.offline'
end


return {
    startup = startup,
    vote = vote,
    result = result,
}
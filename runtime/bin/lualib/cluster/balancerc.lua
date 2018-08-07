local lnet = require 'lnet'
local cluster = require 'cluster.slave'

local math = math
local type = type
local pairs = pairs
local assert = assert

local STUB = {}
local MULTIPLIER = 10000

local balancerd


local function new(...)
    cluster.send(balancerd, 'lua', 'new', ...)
end

local function update(key, inc, maxcounter, step)
    local stub = STUB[key]
    local counter = stub[1] + inc
    counter = math.max(0, counter)
    stub[1] = counter
    local value = math.floor(counter / step) * step / maxcounter
    value = math.floor(value * MULTIPLIER)
    if value ~= stub[3] then
        stub[3] = value
        cluster.send(balancerd, 'lua', 'update', key, value)
    end
end

local function up(key, maxcounter, step)
    update(key, 1, maxcounter, step)
end

local function down(key, maxcounter, step)
    update(key, -1, maxcounter, step)
end

local function query(key)
    return cluster.call(balancerd, 'lua', 'query', key)
end

local function wait(key, n)
    -- 等待 直到类型key的服务有n个上线
    while true do
        local size = cluster.call(balancerd, 'lua', 'size', key)
        if size >= (n or 1) then
            break
        end
		lnet.sleep(1)
    end
end

local function newservice(modname, ...)
    local handle = cluster.gensid()
    local key,callback,extra = require(modname).launch(...)
    assert(type(key) == 'string')
    assert(type(callback) == 'function')
    assert(not STUB[key], ('balance key [%s] has been used'):format(key))
    cluster.dispatch(handle, callback)

    STUB[key] = { 
        0,       -- counter
        handle,  
        0,       -- value or rate ([0~100])
        extra 
    }

    new(key, handle, 0, extra)
end

local function startup()

    -- 处理连接事件
	cluster.concern('balancerd.broken', function()
        balancerd = cluster.wait'balancerd'
        cluster.touch(balancerd)

        for key, stub in pairs(STUB) do
            new(key, table.unpack(stub, 2))
        end
    end)

    lnet.call'balancerd.broken'
end


return {
    startup = startup,
    newservice = newservice,
    up = up,
    down =down,
    query = query,
    wait = wait,
}
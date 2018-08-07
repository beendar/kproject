local log = require 'log'
local lnet = require 'lnet'

local os = os

local head
local tail
local lookup = {}

local duration = 60 -- in seconds


local linger = {}

function linger.add(id, ctx)
    -- make node
    local node = {
        id = id,
        ctx = ctx,
        expire = os.time() + duration
    }
    -- link node to linger list
    if head then
        tail.next = node
        node.prev = tail
        tail = node
    else
        head = node
        tail = node
    end
    -- add lookup
    lookup[id] = node
end

function linger.remove(id)
    local node = lookup[id]
    if node then
        lookup[id] = nil
        -- update linger list
        if node.prev then
            node.prev.next = node.next
        end
        if node.next then
            node.next.prev = node.prev
        end
        if node == head then
            head = node.next
        end
        if node == tail then
            tail = node.prev
        end
        return node.ctx
    end
end

function linger.update(callback)
    local now = os.time()
    while head and now >= head.expire do
        local node = head
        head = head.next
        lookup[node.id] = nil
        local ok,errmsg = lnet.fork(callback, node.ctx)
        if not ok then log.error(errmsg) end
    end
    tail = head and tail or nil
end

function linger.start(callback)
    lnet.timeout(1, math.huge, function()
        linger.update(callback) -- cause hotfix...
        return true
    end)
end


return linger
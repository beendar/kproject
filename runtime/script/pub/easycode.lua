local random = math.random

local redis
local api = {}

local function _generate( origin )
    local next = random(1, 10) + origin
    local head = string.format( '%X', random(128, 255) )
    local body = string.format( '%X', origin )
    local tail = string.format( '%X', random(128, 255) )
    local code = string.format( '%s%s%s', head, body, tail )
    return code, next
end

function generate( origin, count )
    local ret = {}

    for i=1,count do
        local item, no = _generate(origin)
        origin = no
        table.insert( ret, item )
    end

    return ret, origin
end

function api.generate( mainKey, count )
    local incKey = string.format( 'easycodeinc:%s', mainKey )
    local _, origin = redis:incr(incKey)
    local ret, origin = generate(origin, count)
    redis:set(incKey, origin)
    for _, key in ipairs(ret) do
        redis:hset(mainKey, key, '')
    end
    print('Code generate finish!')
end

function api.checkout( key, code )
    local _, r = redis:hget(key, code)
    if r then
        redis:hdel(key, code)
        return r
    end
end

function api.startup(obj)
    redis = obj
end

function api.export( mainKey, path )
    path = path or 'easycode.txt'
    local f = io.open(path, 'w+')
    if not f then
        print('[ERROR] Can not open '..path..',Please change path.')
        return
    end
	local _, ret = redis:hkeys(mainKey)
    for k,code in pairs(ret) do
        f:write(string.format( '%d\t%s\n', k, code ))
    end
    f:close()
    print('Export finish,Path is '..path)
end


return api
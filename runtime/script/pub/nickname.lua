local redis
local badword = require 'badword.core'

local error = error

local RESULT_BADWORD = 1
local RESULT_USED    = 2

local typekey = {
    user = 'hnickname:user',
    clan = 'hnickname:clan',
}

local function check(type, nn)
    local key = typekey[type]
    if not key then
        local errmsg = ('invalid nickname type: %s'):format(type)
        error(errmsg, 2)
    end

	if badword.find(nn) then
		return nil, RESULT_BADWORD 
    end

	local _, n = redis:hsetnx(key, nn, '')
	if n == 0 then
		return nil, RESULT_USED
    end

	return true
end

local function startup(obj)
    redis = obj
end


return {
    startup = startup,
	check = check,
}
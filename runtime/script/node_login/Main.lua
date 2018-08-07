local lnet = require 'lnet'
local cluster = require 'cluster.slave'
local dbopen = require 'pub.dbopen'
local account = require 'pub.account'
local easycode = require 'pub.easycode'
local checksum = require 'crypt'.checksum

local redis

local os = os
local assert = assert

local function selecthost(token)
	local sum = checksum(token)
	return cluster.query('game.gate', 'mod', sum).extra
end

local function activate( token, acct, code )
	local r = easycode.checkout('activation_code', code)
    if r then
        acct.activation_code = r
        account.update(token, acct)
        return true
    else
        return false
    end
end

local HANDLER = {}

HANDLER['LoginLoginServer'] = function(req)
	if req.type == 0 then
		local token = req.token
		assert(token ~= '', 'invalid token')
	
		local acct = account.get(token)
	
		return {
			pid = acct.pid,
			host = selecthost(token),
			secret = os.time(),
		}
	elseif req.type == 1 then
		local token = req.token
		local password = req.password
		assert(token ~= '', 'invalid token')
	
		local acct = account.exist(token, password)
		if acct then
			return {
				pid = acct.pid,
				host = selecthost(token),
				secret = os.time()
			}
		else
			return {
				opcode = 1
			}
		end
	else-- if type == 2 then	
		local token = req.token
		local activation_code = req.activation_code
		assert(token ~= '', 'invalid token')
	
		local acct = account.get(token)
		if not acct.activation_code then
			if activation_code ~= '' then
				if not activate(token, acct, activation_code) then
					return {
						opcode = 3
					}
				end
			else
				return {
					opcode = 2
				}
			end
		end
	
		return {
			pid = acct.pid,
			host = selecthost(token),
			secret = os.time(),
		}
	end
end

HANDLER['RetrieveRegion'] = function()
	return {
		region = {
			{ id=1, name='流放之路' },
			{ id=2, name='魔界塔' },
		}
	}
end


local function startup()
	redis = dbopen.redis'game'
	account.startup(redis)
	easycode.startup(redis)

	cluster.wait'game.gate'
	cluster.register('login', os.pid(), lnet.env'xendpt')

	require 'protocol.load'

	local clientlistener = require 'pub.clientlistener'

	listenfd = clientlistener.start {
		host = lnet.env'ixendpt',
		secret = 'nonce',
		dispatch = function(_, cmd, req)
			return HANDLER[cmd](req), true
		end
	}
end


return {
	startup = startup
}
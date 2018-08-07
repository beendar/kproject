local log = require 'log'
local cluster = require 'cluster.slave'


local codeserver
function _G.push(type)
	codeserver = codeserver or cluster.wait'codeserver.push'
	log.print('\n%s', cluster.call(codeserver, 'lua', type))
end

local remote
local function execute(cmdstr)
	if cmdstr:byte() ~= 33 then -- 33 is '!'
		assert(loadstring(cmdstr))()
	else
		if not remote then
			remote = cluster.wait'game.remote'
			cluster.concern('game.broken', function()
				remote = cluster.wait'game.remote'
				cluster.touch(remote)
			end)
		end
		dump {
			cluster.call(remote, 'lua', cmdstr:sub(2))
		}
	end
end


return {
	startup = function()
		require 'lnet.terminal'.dispatch(execute)
	end
}
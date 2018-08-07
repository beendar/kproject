local cluster = require 'cluster.slave'
local codecache = require 'codecache'
local socket = require 'socket'

function _G.new(token, password, type, rgnid, host)
	host = host or cluster.wait'login'.extra
	local nonce = os.time()
	local sock, r = socket.open(host, nonce, 
		'LoginLoginServer', {
			token = token,
			password = password,
			activation_code = password,
			nonce = nonce,
			type = type,
		})		
	sock:close()

	if r.pid ~= '' then
		return codecache.call('bot', r.pid, rgnid or 1, r.host, r.secret)
	else
		print('token, fd, recv failed', token, sock.fd % 65536)
		print(r.opcode)
	end
end

return {
	startup = function()
		require 'protocol.load'
		require 'remotecli'.startup()
	end
}
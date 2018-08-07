local sockdriver = require'lnet.sockdriver'
local dns = require'dns'
local encode = require'crypt'.base64encode
local decode = require'crypt'.base64decode

local ipairs = ipairs
local assert = assert

local function open(domain)
	local host = dns.resolve(domain)
	local port = 25
	local fd = sockdriver.connect(host, port)
	if not fd then return end
	sockdriver.setopt(fd, 'datatype', 1)
	sockdriver.setopt(fd, 'recvtimeout', 30)
	return fd
end

local function request(fd, req, row)
	sockdriver.send(fd, req)
	local ok
	for n=1, row do
		ok = sockdriver.recv(fd, '\r\n')
		if not ok then break end
	end
	return ok
end


local smtp = {}

function smtp.send(mail)
	--check parameters
	local server   = assert(mail.server, 'smpt error: server is nil')
	local username = assert(mail.username, 'smpt error: username is nil')
	local password = assert(mail.password, 'smpt error: password is nil')
	local receiver = assert(mail.receiver, 'smtp error: receiver is nil')
	local content  = assert(mail.content, 'smtp error: content is nil')
	local subject  = mail.subject or ''

	local step_content = 
	{
		'EHLO ' .. username .. '\r\n',
		'auth login\r\n',
		encode(username) .. '\r\n',
		encode(password) .. '\r\n',
		('mail from: <%s>\r\n'):format(username),
		('rcpt to: <%s>\r\n'):format(receiver),
		'data\r\n',
([[
subject: %s

%s
.

]]):format(subject, content),
		'quit\r\n'
	}


	local fd = open(server)
	if not fd then
		return
	end

	local ok = sockdriver.recv(fd, '\r\n')
	if not ok then
		return
	end

	for idx, data in ipairs(step_content) do
		local row = (idx==1) and 7 or 1
		ok = request(fd, data, row)
		if not ok then break end
	end

	sockdriver.close(fd)

	return (ok ~= nil)
end


return smtp
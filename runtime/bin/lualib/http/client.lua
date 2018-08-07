local assert = assert
local socket = require 'http.socket'

local CLI_GET  = "GET %s?%s HTTP/1.1\r\nHOST: %s\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\n"
local CLI_POST = "POST %s HTTP/1.1\r\nHOST: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %s\r\n\r\n%s"


local function dorequest(domain, req)--{{{
	local sock = socket.open(domain)
	sock:write(req)
	local header, body = sock:read()
	sock:close()
	return header, body
end--}}}

local function GET(t)--{{{
	assert(t.host, 'host not set')
	local req = CLI_GET:format(t.method or '/', t.body or '', t.host)
	return dorequest(t.host, req)
end--}}}

local function POST(t)--{{{
	assert(t.host, 'host not set')
	local body = t.body or ''
	local req = CLI_POST:format(t.method or '/', t.host, #body, body)
	return dorequest(t.host, req)
end--}}}

return {
	GET  = GET,
	POST = POST,
}

local socket = require 'http.socket'

local table = table
local string = string
local pcall = pcall
local assert = assert


local TEXT = {
	[200] = 'OK',
	[500] = 'Internal Server Error',
}

local function response(code, resp, callback)--{{{
	-- status
	local msg = {
		string.format('HTTP/1.1 %d %s', code, TEXT[code]),
		string.format('Server: lnet'),
		string.format('Access-Control-Allow-Origin: *'),
	}

	-- content type
	local datatype
	if code == 500 then
		datatype = 'text'
	else
		datatype = resp.datatype or 'text'
	end

	table.insert(msg, string.format('Content-Type: %s', datatype))

	-- handle data
	local data
	if code == 500 then
		-- runtime error occourred, resp is error message string
		data = resp 
	else
		data = resp.data
		-- jsonp callback
		if callback then
			data = string.format('%s(%s)', callback, data)
		else
		end
	end

	-- data length
	table.insert(msg, string.format('Content-Length: %d', #data))

	-- separator
	table.insert(msg, '')

	-- response data
	table.insert(msg, data)

	return table.concat(msg, '\r\n')
end--}}}

local function start(t)
	local host = assert(t.host, 'host not set')
	local dispatch = assert(t.dispatch, 'dispatch not set')
	local listensock = 
	socket.listen(host, function(header, body)
		local ok, r = pcall(dispatch, header, body)
		return response(ok and 200 or 500, r, body.callback)
	end)
	return listensock
end


return {
	start = start
}
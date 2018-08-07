local lnet = require 'lnet'
local cjson = require 'extend.cjson'
local handler = require 'handler'


local function checksign(data, sign)
	return true
end

local function dispatch(header, body)
	local f = handler[header.method]
	asserti(f, string.format('无效的方法: %s', header.method))

	local ok = checksign(body.data, body.sign)
	asserti(ok, '错误的签名')

	local ok, req = pcalli(cjson.decode, body.data)
	asserti(ok, string.format('JSON解包失败: %s', req))

	return f(req)
end

local function startup()
	local httpserver = require 'http.server'

	listenfd = httpserver.start {
		host = lnet.env'ixendpt',
		dispatch = function(header, body)
			local ok, r = pcalli(dispatch, header, body)
			return {
				datatype = 'application/json;charset=utf-8',
				data = cjson.encode {
					ok = ok,
					data = r or ''
				}
			}
		end
	}
end


return {
	startup = startup
}
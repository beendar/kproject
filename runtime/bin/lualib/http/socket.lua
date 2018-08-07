local dns = require 'dns'
local parser = require 'http.parser'
local sockdriver = require 'lnet.sockdriver'

local pcall = pcall
local assert = assert
local setmetatable = setmetatable


local function readline(fd)
    return sockdriver.recv(fd, '\r\n')
end

local function read(fd, n)
    return sockdriver.recv(fd, n)
end

local function readhttpmsg(fd)
    local header = {}
    local body = {}

    -- 收第一行
    local firstline = readline(fd)

    -- 分析第一行
    local type = parser.capture(firstline, '(%w+)')

    if type == 'HTTP' then
        header.code = parser.capture(firstline, '%s(%d+)%s')
    else
        header.method = parser.capture(firstline, '([^%s%?]+)', #type+1)
    end

    -- 收包头
    while true do
        local line = readline(fd)
        if #line > 0 then
            local k, v = parser.parseline(line)
            if k then
                header[k] = v
            end
        else
            break
        end
    end

    -- 提取GET方法的数据
    if type == 'GET' then
        body.__data = parser.capture(firstline, '%?(%S+)') or ''
    end

    -- 收包体
    if type == 'POST' or header.code then
        if header['content-length'] then
            body.__data = read(fd, header['content-length'])
        elseif header['transfer-encoding'] == 'chunked' then
            local chunk = {}
            local fin = '1'
            while fin ~= '0' do
                local len = readline(fd)
                local data = readline(fd)
                fin = readline(fd)
                table.insert(chunk, data)
            end
            body.__data = table.concat(chunk)
        end
    end

    -- 删除控制字符
    body.__data = body.__data:gsub('[%c]', '')

    -- 提取KV
    local decoded = parser.urldecode(body.__data)
	for k,v in decoded:gmatch'([^=&]+)=([^&]+)' do
		body[k] = v
	end
	body._RAWDATA = decoded 
	body.__data = nil
    
    return header, body
end


local socket = {}
setmetatable(socket, socket)

socket.__index = socket
socket.__call = function(mt, fd, bsetopt)
    if bsetopt then
    	sockdriver.setopt(fd, 'datatype', 1)
    	sockdriver.setopt(fd, 'recvbuffer', 64*1024)
    	sockdriver.setopt(fd, 'recvtimeout', 30)
	end
    return setmetatable({fd=fd}, mt)
end


function socket:read()
    local ok, header, body = pcall(readhttpmsg, self.fd)
    if ok then
        return header, body
    end
    return nil, header
end

function socket:write(data, shutdown)
    sockdriver.send(self.fd, data, shutdown)
end

function socket:close()
    sockdriver.close(self.fd)
end


local function open(domain)
    local host = parser.capture(domain, '([^:]+)')
    local port = parser.capture(domain, ':(%d+)$') or 80
    host = dns.resolve(host)
    port = tonumber(port)
    local fd = sockdriver.connect(host, port)
    if fd then
        return socket(fd, true)
    end
end

local function listen(endpt, callback)
    local listenfd = 
    sockdriver.listen(endpt, function(fd)
        local sock = socket(fd, true)
        local header, body = sock:read()
        if header then
            local resp = callback(header, body)
            sock:write(resp, true)
        end
        sock:close()
    end)
    return socket(listenfd)
end


return {
    open = open,
    listen = listen
}
local lnet = require 'lnet'
local logdriver = require 'lnet.logdriver'

local os = os
local math = math
local difftime = difftime

local PFMT_PRINT = '[LUA-PRINT]: %s \n '
local PFMT_ERROR = '[LUA-ERROR]: %s \n '
local WFMT_PRINT = '[LUA-PRINT]:\t%s\t'
local WFMT_ERROR = '[LUA-ERROR]:\t%s\t'

local _path
local _opened

local function getdatetime()--{{{
	return os.date'%Y-%m-%d %H:%M:%S'
end--}}}

local function enable(b)
	logdriver.setopt('console', b and 1 or 0)
end

local function print(fmt, ...)--{{{
	logdriver.print(PFMT_PRINT:format(getdatetime()), fmt:format(...))
end--}}}

local function error(fmt, ...)--{{{
	logdriver.print(PFMT_ERROR:format(getdatetime()), fmt:format(...))
end--}}}

local function newday()--{{{
	local fname = ('%s/%s.txt'):format(_path, os.date'%Y-%m-%d_%H-%M-%S')
	logdriver.close()
	_opened = logdriver.open(fname)
	return true
end--}}}

local function startup(path)--{{{
	if path then
		_path = path
		os.makedir(_path, '/')
		newday()
		logdriver.setopt('batch', 2, 4096)
		lnet.timeoutx(difftime(), 24*3600, math.huge, newday)
	end
end--}}}


return {
	startup = startup,
	enable = enable,
	print = print,
	error = error
} 
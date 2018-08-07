local lnet = require 'lnet'
local dbopen = require 'pub.dbopen'

local function startup()
	-- 节点内共享mongo.game驱动
	local driver = dbopen.mongo'game'
	local db = driver:getdb'kgame'
	lnet.setenv('driver', driver)
	lnet.setenv('db', db)

	-- 加载gamedata
	require 'gamedata.load'
	require 'gamedata.transform'

	-- 加载protocol
	require 'protocol.load'

	-- 逻辑模块初始化
	require 'pub.nickname'.startup(dbopen.redis'game')
	require 'gamesys.mail'.startup(dbopen.mongo'mail')
	require 'gamesys.mall'.startup()

	-- 订阅依赖服务
	require 'cluster.slave'.wait'chat.manager'
	require 'cluster.slave'.wait'clan.manager'

	-- DEBUG 对虚拟客户端远程代码执行服务
	require 'cluster.slave'.newservice'gamesys.remote'

	-- gate开启监听
	require 'module.gate'.startup()
end


return {
	startup = startup
}
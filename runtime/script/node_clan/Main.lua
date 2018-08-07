local lnet = require 'lnet'
local cluster = require 'cluster.slave'
local dbopen = require 'pub.dbopen'

local function startup()
    -- 节点内共享mongo.game驱动
	local driver = dbopen.mongo'game'
	local db = driver:getdb'kgame'
	lnet.setenv('driver', driver)
	lnet.setenv('db', db)

	-- 逻辑模块初始化
	require 'pub.genid'.startup(dbopen.redis'game')

	-- 启动对集群服务
	require 'cluster.slave'.newservice'manager'
end


return {
    startup = startup
}
return {

	clustermaster = {iendpt='localhost:11900'},

	['conf.mongo.game'] = {
		user = 'root',
		pass = 'beendar1982',
		ti_batch = 0.001,       -- 批量提交超时 最小值1毫秒
		ti_ping = 2.0,          -- 心跳超时
		ti_recv = 7.0,          -- 接收超时
		--'192.168.0.66:45369'  -- lan host
		'127.0.0.1:45369'		-- localhost (for local testing)
	},

	['conf.mongo.mail'] = {
		user = 'root',
		pass = 'beendar1982',
		ti_batch = 0.001,       -- 批量提交超时 最小值1毫秒
		ti_ping = 2.0,          -- 心跳超时
		ti_recv = 7.0,          -- 接收超时
		--'192.168.0.66:45369'  -- lan host
		'127.0.0.1:45369'		-- localhost (for local testing)
	},

	['conf.redis.game'] = {
		pass = 'yangzhaolinisgoodguy',
		ti_batch = 0.001,		-- 批量提交超时 最小值1毫秒
		ti_ping = 2.0,			-- 心跳超时
		ti_recv = 7.0,			-- 接收超时
		--'192.168.0.66:32541',	-- lan host
		'127.0.0.1:32541',		-- localhost (for local testing)
	}
}

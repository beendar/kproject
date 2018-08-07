local t = {
	[1] = {
		weekly_point=10,
		weekly_reward={
			{tid=100,count=4},
			{tid=200,count=4},
			{tid=300,count=4},
		},
		daily_point=10,
		daily_reward={
			{tid=20,count=31},
			{tid=40,count=32},
			{tid=60,count=33},
			{tid=80,count=34},
			{tid=100,count=35},
		},
	},
}

require'metadata'.new('mission_config', t)
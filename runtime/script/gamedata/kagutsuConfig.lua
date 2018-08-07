local t = {
	[1] = {
		processReward={10001,10002,10003,10004},
		reset={
			{tid=6002,count=20},
		},
	},
	[2] = {
		processReward={10005,10006,10007,10008},
		reset={
			{tid=6002,count=21},
		},
	},
	[3] = {
		processReward={10009,10010,10011,10012},
		reset={
			{tid=6002,count=22},
		},
	},
	[4] = {
		processReward={10013,10014,10015,10016},
		reset={
			{tid=6002,count=23},
		},
	},
}

require'metadata'.new('kagutsuConfig', t)
local t = {
	[1] = {
		player_exp=1,
		id=1,
		guard_time=300,
		battle_reward_energy={1,4},
		refresh_time=300,
		battle_reward_coin={1,4},
		role_exp=1,
		stage_reward_1={30000,1},
		stage_reward_2={30000,2},
	},
}

require'metadata'.new('kingbattlecommon', t)
local t = {
	[1] = {
		min=10000,
		name="Stone",
		max=19999,
	},
	[2] = {
		min=1000,
		name="Gift",
		max=1999,
	},
	[3] = {
		min=2000,
		name="Fragment",
		max=2999,
	},
	[4] = {
		min=3000,
		name="Awake",
		max=3999,
	},
	[5] = {
		min=200,
		name="StoneExp",
		max=999,
	},
	[6] = {
		min=4000,
		name="StoneFragment",
		max=4999,
	},
	[7] = {
		min=1,
		name="Exp",
		max=199,
	},
	[8] = {
		min=5000,
		name="Lottery",
		max=5999,
	},
	[9] = {
		min=6000,
		name="Consumable",
		max=6199,
	},
	[10] = {
		min=7000,
		name="Merge",
		max=7999,
	},
	[11] = {
		min=6200,
		name="Energy",
		max=6299,
	},
	[12] = {
		min=6300,
		name="Chest",
		max=6399,
	},
	[101] = {
		min=40000,
		name="Energy",
		max=41000,
	},
	[100] = {
		min=30000,
		name="Money",
		max=31000,
	},
	[102] = {
		min=50000,
		name="Cexp",
		max=51000,
	},
	[103] = {
		min=60000,
		name="Aexp",
		max=60999,
	},
	[200] = {
		min=61000,
		name="Package",
		max=61999,
	},
}

require'metadata'.new('idrange', t)
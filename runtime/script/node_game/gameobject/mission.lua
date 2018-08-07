local metadata = require'metadata'

local mission = metadata.mission
local awards = metadata.awards
local conf = metadata.mission_config[1]

local itemsys = require'gamesys.item'

---@class mission
local interface = {}


function interface:refresh()
	local now = os.time()
	if self.daily_et < now then
		self.daily_et = now + difftime(0,0,0)
		local ms = {}
		for i,v in pairs(mission) do
			if v.missionType == 3 then
				ms[i] = {
					mid = i,
					value = 0,
					type = 'daily'
				}
			end
		end
		self.daily = ms
		self.daily_point = 0
		self.daily_point_reward = {}
	end

	if self.weekly_et < now then
		self.weekly_et = now + diffwdaytime(1)
		local ms = {}
		for i,v in pairs(mission) do
			if v.missionType == 4 then
				ms[i] = {
					mid = i,
					value = 0,
					type = 'weekly'
				}
			end
		end
		self.weekly = ms
		self.weekly_point = 0
		self.weekly_point_reward = {}
	end
end

function interface:update(ms)
	for _,v in pairs(ms) do
		local obj = self[v.type][v.mid]
		if obj then
			obj.value = obj.value + v.value
			obj.complete = obj.value >= mission[v.mid].targ[1]
		else
			if not mission[v.mid] then
				assert(nil, 'mid = '..v.mid..'is not find this mission')
			end
			self[v.type][v.mid] = {
				mid = v.mid,
				value = v.value,
				complete = v.value >= mission[v.mid].targ[1]
			}
		end
	end
end

function interface:reward( req )
	local lst = self[req.type]
	if not lst then
		return false
	end

	if req.type == 'daily_point' or req.type == 'weekly_point' then
		local tc
		local rtable = req.type == 'daily_point' and conf.daily_reward or conf.weekly_reward
		for k,v in pairs(rtable) do
			if v.tid == req.mid then
				tc = v.count
				break
			end
		end
		if not tc then
			return false
		end

		local drop = awards[tc].dropList
		local ret = itemsys.gen(drop, self.Model)
		itemsys.apply(ret, self.Model)

		if self[req.type..'_reward'] then
			self[req.type..'_reward'][#self[req.type..'_reward'] + 1] = req.mid
		else
			self[req.type..'_reward'] = { req.mid }
		end

		return true
	else
		v = lst[req.mid]
		assert(v and not v.got_reward, 'mission is got reward! can not get again.')

		local drop = awards[mission[req.mid].reward].dropList
		local ret = itemsys.gen(drop, self.Model)
		itemsys.apply(ret, self.Model)

		if mission[req.mid].missionType == 3 then
			self.daily_point = self.daily_point + conf.daily_point
			v.got_reward = true
		elseif mission[req.mid].missionType == 4 then
			self.weekly_point = self.weekly_point + conf.weekly_point
			v.got_reward = true
		else
			self.complete[#self.complete + 1] = req.mid
			lst[req.mid] = nil
		end

		return true
	end
end


return interface
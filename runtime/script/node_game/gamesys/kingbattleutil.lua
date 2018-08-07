local diffwdaytime = diffwdaytime

local os = os
local math = math

local season_id


local function season()
    local now = os.time()
    if not season_id or now > season_id then
        season_id = now + diffwdaytime(1, 0, 0, 0)
    end
    return season_id 
end


return {
    season = season
}
local extractsys = require 'gamesys.extract'


local HANDLER = {}

HANDLER['ExtractCard'] = function(u, req)
	extractsys.check(u.model, req.count)
	return extractsys.card(u.model, req.count)
end


return HANDLER
local archivesys = require 'gamesys.archive'
local factory = require 'gameobject.factory'


local sloader = {}

function sloader.load(colname, model)
    local data = model.archive[colname]
    if not data then
        data = archivesys.loadone(colname, model.pid, model.rgnid)
        model.archive[colname] = data
    end

    return factory.construct(colname, data, model)
end


return sloader
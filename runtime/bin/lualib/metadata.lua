local conf = require'luaconf'


local metadata = {}

function metadata.new(name, t)
	local old = metadata[name]
	if old then
		conf.host.delete(old.__obj)
		metadata[name] = nil
	end

	metadata[name] = conf.box( conf.host.new(t) )

	return metadata[name]
end


return metadata
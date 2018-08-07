local log = require 'log'
local codecache = require 'codecache'


local HANDLER = table.hotfix{}

table.copy(HANDLER, codecache.call'message.system')
table.copy(HANDLER, codecache.call'message.friend')
table.copy(HANDLER, codecache.call'message.mail')
table.copy(HANDLER, codecache.call'message.jungle')
table.copy(HANDLER, codecache.call'message.committal')
table.copy(HANDLER, codecache.call'message.role')
table.copy(HANDLER, codecache.call'message.battle')
table.copy(HANDLER, codecache.call'message.extract')
table.copy(HANDLER, codecache.call'message.fogmaze')
table.copy(HANDLER, codecache.call'message.kagutsu')
table.copy(HANDLER, codecache.call'message.clan')
table.copy(HANDLER, codecache.call'message.mission')
table.copy(HANDLER, codecache.call'message.mall')
table.copy(HANDLER, codecache.call'message.guide')
table.copy(HANDLER, codecache.call'message.island')
table.copy(HANDLER, codecache.call'message.kingbattle')


local empty = {}
return function(u, cmd, ...)

	--TODO: delete
	log.print('client [%s]: %s', u.pid, cmd)
	local st = os.now()

	local r = HANDLER[cmd](u, ...) or empty


	--TODO: delete
	local tip = ('time cost: %.9f seconds'):format(os.now() - st)
	print(tip)

	u.model:save()
	return r
end

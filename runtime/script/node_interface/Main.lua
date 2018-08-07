local lnet = require 'lnet'
local dbopen = require 'pub.dbopen'


local function startup()
	local drv_game = dbopen.mongo'game'
	local drv_mail = dbopen.mongo'mail'
	lnet.setenv('drv_game', drv_game)
	lnet.setenv('drv_mail', drv_mail)
	lnet.setenv('gamedb', drv_game:getdb'kgame')
	lnet.setenv('maildb', drv_game:getdb'kgame')
	require 'gamedata.load'
	require'mailsys'.startup()
	require'interface'.startup()
end

return {
	startup = startup
}
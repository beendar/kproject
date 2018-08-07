require 'preload'
require 'lnet'.init(...)
require 'cluster.slave'.startup()
require 'cluster.arbitratec'.startup()
require 'cluster.multicastc'.startup()
require 'cluster.dictionaryc'.startup()
--require 'cluster.balancerc'.startup()
require 'codecache.slave.core'.startup'Main'
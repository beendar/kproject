local lnet = require 'lnet'
local bson = require 'database.mongo.bson'

local table = table
local next = next
local pairs = pairs

local mongo = lnet.env'db'
local proxy = require 'db.mgo.proxy'(mongo)
proxy:addspec('base')
proxy:addspec('bag')
proxy:addspec('friend', 'fpid', 's')
proxy:addspec('role', 'tid', 'n')
proxy:addspec('stone', 'sn', 'n')
proxy:addspec('pmethod', 'methodid', 'n')
proxy:addspec('chapter', 'tid', 'n')
proxy:addspec('committal', 'tid', 'n')
proxy:addspec('jungle', 'sn', 'n')
proxy:addspec('kagutsu')
proxy:addspec('mission')
proxy:addspec('mallrecord')
proxy:addspec('kingbattle')
proxy:addspec('island')


local cond = { pid={} }
local selector = {
	_id=0, pid=1, nickname=1, headid=1,
    mask=1, plv=1, medal=1, online=1, offline=1
 }

local function loadfriends(rgnid, simplelist)
	cond.rgnid = rgnid
    cond.pid['$in'] = bson.array(table.keys(simplelist))

    local verbose = mongo:getcol'base':find(cond, selector):totable'pid'
    for pid, friend in pairs(verbose) do
        table.copy(friend, simplelist[pid])
    end

    return verbose
end

local selector = { _id=0, pid=0, rgnid=0 }
local function rawload(pid, rgnid)
	local cond = { pid=pid, rgnid=rgnid }

	-- create new archive if no record in database
	local r
	local base = proxy:load('base', cond) -- using default selector { _id=0 }

	if not base then
		r = require'gamesys.default'.new(pid, rgnid)
		for colname, t in pairs(r) do
			proxy:insert(colname, t)
		end	
	end

	-- or reading from database
	r = r or {
		base    = base,
		bag     = proxy:load('bag', cond, selector),
		role    = proxy:load('role', cond, selector),
		stone   = proxy:load('stone', cond, selector),
		pmethod = proxy:load('pmethod', cond, selector),
		chapter = proxy:load('chapter', cond, selector),
		committal = proxy:load('committal', cond, selector),
		jungle = proxy:load('jungle', cond, selector),
        friend = proxy:load('friend', cond, selector),
	}

	-- try loading verbose friend list
	if base and next(r.friend) then
		r.friend = loadfriends(rgnid, r.friend)
	end

	return r, cond
end

local function load(pid, rgnid)
	local r, cond = rawload(pid, rgnid)

	-- may r is newly created archive, clear fields that affect protobuf encoding
	r.bag.pid = nil
	r.bag.rgnid = nil

	-- bind database synchro
	for colname, t in pairs(r) do
		r[colname] = proxy:bind(t, colname, cond)
	end

	return r
end

local function loadone( colname, pid, rgnid )
	local cond = { pid=pid, rgnid=rgnid }
	local doc = proxy:load(colname, cond, selector)
	return proxy:bind(doc, colname, cond)
end

local function ismultiple( colname )
	return proxy:getspeckey(colname)
end


return {
	load = load,
	rawload = rawload,
	loadone = loadone,
	ismultiple = ismultiple,
}
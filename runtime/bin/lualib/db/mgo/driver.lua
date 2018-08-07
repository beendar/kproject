local lnet   = require 'lnet'
local crypt  = require 'crypt'
local bson   = require 'database.mongo.bson'
local proto  = require 'database.mongo.proto'
local client = require 'database.mongo.client'

local math   = math
local next   = next
local pairs  = pairs
local assert = assert
local tostring = tostring
local setmetatable = setmetatable

local empty = {}

--makes 'op set' as default operation
--when caller do not specific explicit operation type
--otherwise, using op as update command directly
local sharedop = {}

local function selectop(op)--{{{
	if (not op['$set']) and (not op['$unset']) and (not op['$inc']) then
		sharedop['$set'] = op
		return sharedop
	end
	return op
end--}}}

local function makeindexlist(...)
	local list = {...}
	for i=1, #list do
		table.insert(list, i+i, 1)
	end
	return list
end



--Cursor interface
local mt_cursor = {}
mt_cursor.__index = mt_cursor 

function mt_cursor.new(ns, cond, fields, db)
	local cursor = {
		_ns = ns,
		_cond = { query=cond },
		_fields = fields or empty,
		_db = db,
		_limit = 100,
		_skip = 0,
		_count = 0,
		_sent = false,
	}
	return setmetatable(cursor, mt_cursor)
end

function mt_cursor:limit(n)
	self._limit = n
	return self
end

function mt_cursor:skip(n)
	self._skip = n
	return self
end

function mt_cursor:sort(...)
	self._cond.orderby = bson.encode_order(...)
	return self
end

function mt_cursor:next()

	if not self._sent then

		local req = proto.query(self._ns, self._cond, self._fields, self._limit, self._skip)
		self._buffer, self._length, self._cursorid = self._db:commit(req)
		self._sent = true

	else

		local count = self._count + 1
		self._count = count

		-- consumed count has been equal to limit count
		if count >= self._limit then
			if self._cursorid > 0 then
				self._db:commit( proto.kill(self._cursorid) )
			end
			return nil
		end

		-- update buffer and length
		self._buffer, self._length = proto.next(self._buffer, self._length)

		-- no data on client side, but may still some more data on server side
		if self._length == 0 and self._cursorid > 0 then

			-- tell server getting more data
			local req = proto.more(self._ns, self._limit - count, self._cursorid)
			self._buffer, self._length = self._db:commit(req)

			-- no more data here, tell server killing cursor
			if self._length == 0 then
				self._db:commit( proto.kill(self._cursorid) )
			end
		end
	end

	if self._length > 0 then
		return proto.unpack(self._buffer)
	end
end

function mt_cursor:__pairs()
	return self.next, self
end

function mt_cursor:totable(key)
	local tb  = {}
	for r in pairs(self) do
		tb[r[key]] = r
	end
	return tb
end

function mt_cursor:toarray()
	local tb  = {}
	for r in pairs(self) do
		tb[#tb+1] = r
	end
	return tb
end

--Collection interface
local mt_collection = {}
mt_collection.__index = mt_collection

function mt_collection.new(db, name)--{{{
	local inst = {
		db = db,
		name = name,
		ns = ('%s.%s'):format(db.name, name),
	}
	return setmetatable(inst, mt_collection)
end--}}}

function mt_collection:namespace()--{{{
	return self.ns
end--}}}

function mt_collection:find_one(cond, fields)--{{{
	return self:find(cond,fields):limit(1):next()
end--}}}

function mt_collection:find(cond, fields)--{{{
	return mt_cursor.new(self.ns, cond, fields, self.db)
end--}}}

function mt_collection:find_modify(cond, fields, op, new, upsert)--{{{
	return self.db:run_command(
			'findAndModify', self.name,
			'query',  cond,
			'fields', fields,
			'update', selectop(op),
			'new',   (new and true or false),
			'upsert', (upsert and true or false)).value
end--}}}

function mt_collection:find_remove(cond, fields)
	return self.db:run_command(
			'findAndModify', self.name,
			'query',  cond,
			'fields', fields,
			'remove', true).value
end

function mt_collection:count(cond)--{{{
	return self.db:run_command(
			'count', self.name, 
			'query', cond or empty).n
end--}}}

function mt_collection:concern()--{{{
	local err = self.db:run_command('getlasterror', 1).err
	if not err then
		return true
	end
	return false, err
end--}}}

function mt_collection:insert(doc)--{{{
	return self:batch_insert{doc}
end--}}}

function mt_collection:batch_insert(docs)--{{{
	if not next(docs) then return end
	local req = proto.insert(self.ns, docs)
	self.db:commit(req)
	return self
end--}}}

function mt_collection:update(cond, op, opt)--{{{
	-- opt can be: UPSERT=1, MULTI=2, BASIC=4
	local req = proto.update(self.ns, cond, selectop(op), opt)
	self.db:commit(req)
	return self
end--}}}

function mt_collection:remove(cond)--{{{
	local req = proto.remove(self.ns, cond)
	self.db:commit(req)
	return self
end--}}}

function mt_collection:drop()
	local r = self.db:run_command('drop', self.name)
	return (r.ok == 1), r.errmsg
end

function mt_collection:listindex()--{{{
	local r = self.db:run_command('listIndexes', self.name)
	if r.ok == 1 then
		return true, r.cursor.firstBatch
	end
	return false, r.errmsg
end--}}}

function mt_collection:dropindex(...)
	local list = makeindexlist(...)
	local name = table.concat(list, '_')
	local r = self.db:run_command('dropIndexes', self.name, 'index', name)
	return (r.ok == 1), r.errmsg
end

function mt_collection:ensureindex(...)
	local list = makeindexlist(...)
	local key = bson.encode_order(table.unpack(list))
	local name = table.concat(list, '_')
	local r = self.db:run_command(
			'createIndexes', self.name,
		    'indexes', bson.array { 
							{ key=key, name=name } 
						})
	return (r.ok==1), r.errmsg
end

function mt_collection:aggregate(pipeline)
	return self.db:run_command(
		'aggregate', self.name,
		'pipeline', bson.array(pipeline)
	)
end

--Database interface
local mt_database = {}
mt_database.__index = mt_database

function mt_database.new(c, name)--{{{
	local inst = {
		c = c,
		name = name,
		cmdname = name .. '.$cmd',
		collection = {}
	}
	return setmetatable(inst, mt_database)
end--}}}

function mt_database:getcol(name)--{{{
	local collection = self.collection[name]
	if not collection then
		collection = mt_collection.new(self, name)
		self.collection[name] = collection
	end
	return collection
end--}}}

function mt_database:commit(req)
	return self.c:commit(req, false)
end

local function run_command(self, hpriority, ...)
	local cmd = bson.encode_order(...)
	local req = proto.query(self.cmdname, cmd, empty, 1, 0)
	local buffer,length = self.c:commit(req, hpriority)
	if length > 0 then
		return proto.unpack(buffer)
	end
end

function mt_database:run_command(...)--{{{
	return run_command(self, false, ...)
end--}}}

function mt_database:add_user(user, pwd)--{{{
	local r = 
	self:run_command('createUser', user,
					'pwd', pwd,
					'roles', bson.array {
						{role="userAdminAnyDatabase",db=self.name},
						{role="readWriteAnyDatabase",db=self.name}
					})

	return (r.ok == 1)
end--}}}

local function salt_password(pass, salt, iter)--{{{
	salt = salt .. "\0\0\0\1"
	local output = crypt.hmac_sha1(pass, salt)
	local inter = output
	for i=2,iter do
		inter = crypt.hmac_sha1(pass, inter)
		output = crypt.xor_str(output, inter)
	end
	return output
end--}}}

function mt_database:auth_scram_sha1(user, pass)--{{{
	local user = string.gsub(string.gsub(user, '=', '=3D'), ',' , '=2C')
	local nonce = crypt.base64encode(crypt.randomkey())
	local first_bare = "n="  .. user .. ",r="  .. nonce
	local sasl_start_payload = crypt.base64encode("n,," .. first_bare)
	local r

	r = run_command(self,true,"saslStart",1,"autoAuthorize",1,"mechanism","SCRAM-SHA-1","payload",sasl_start_payload)
	if r.ok ~= 1 then
		return false
	end

	local conversationId = r['conversationId']
	local server_first = r['payload']
	local parsed_s = crypt.base64decode(server_first)
	local parsed_t = {}
	for k, v in string.gmatch(parsed_s, "(%w+)=([^,]*)") do
		parsed_t[k] = v
	end
	local iterations = tonumber(parsed_t['i'])
	local salt = parsed_t['s']
	local rnonce = parsed_t['r']

	if not string.sub(rnonce, 1, 12) == nonce then
		print("Server returned an invalid nonce.")
		return false
	end
	local without_proof = "c=biws,r=" .. rnonce
	local pbkdf2_key = crypt.md5(string.format("%s:mongo:%s",user,pass))
	local salted_pass = salt_password(pbkdf2_key, crypt.base64decode(salt), iterations)
	local client_key = crypt.hmac_sha1(salted_pass, "Client Key")
	local stored_key = crypt.sha1(client_key)
	local auth_msg = first_bare .. ',' .. parsed_s .. ',' .. without_proof
	local client_sig = crypt.hmac_sha1(stored_key, auth_msg)
	local client_key_xor_sig = crypt.xor_str(client_key, client_sig)
	local client_proof = "p=" .. crypt.base64encode(client_key_xor_sig)
	local client_final = crypt.base64encode(without_proof .. ',' .. client_proof)
	local server_key = crypt.hmac_sha1(salted_pass, "Server Key")
	local server_sig = crypt.base64encode(crypt.hmac_sha1(server_key, auth_msg))

	r = run_command(self,true,"saslContinue",1,"conversationId",conversationId,"payload",client_final)
	if r.ok ~= 1 then
		return false
	end
	parsed_s = crypt.base64decode(r['payload'])
	parsed_t = {}
	for k, v in string.gmatch(parsed_s, "(%w+)=([^,]*)") do
		parsed_t[k] = v
	end
	if parsed_t['v'] ~= server_sig then
		print("Server returned an invalid signature.")
		return false
	end
	if not r.done then
		r = run_command(self,true,"saslContinue",1,"conversationId",conversationId,"payload","")
		if r.ok ~= 1 then
			return false
		end
		if not r.done then
			print("SASL conversation failed to complete.")
			return false
		end
	end
	return true
end--}}}

function mt_database:auth_cr(user, pass)--{{{
	local nonce = run_command(self,true,'getnonce',1).nonce
	local pass_digit = crypt.md5(user, ':mongo:', pass)
	local auth_digit = crypt.md5(nonce, user, pass_digit)
	local r = run_command(self,true,'authenticate',1,'user',user,'nonce',nonce,'key',auth_digit)
	return (r.ok == 1)
end--}}}

function mt_database:authenticate(conf)--{{{
	local user = conf.user
	local pass = conf.pass
	local mode = conf.mode or 'sha1'
	if user and pass then
		assert(mode == 'cr' or mode == 'sha1', 'invalid auth mode')
		if mode == 'cr' then
			return self:auth_cr(user, pass)
		end
		return self:auth_scram_sha1(user, pass)
	end
	return true
end--}}}


--Driver interface
local mt_driver = {}
mt_driver.__index = mt_driver

function mt_driver.new()--{{{
	local inst = {
		c = client.new(),
		database = {}
	}
	lnet.xpipe(tostring(inst))
	return setmetatable(inst, mt_driver)
end--}}}

function mt_driver:getdb(name)--{{{
	local database = self.database[name]
	if (not database) then
		database = mt_database.new(self.c, name)
		self.database[name] = database
	end
	return database
end--}}}

function mt_driver:concern(callback)
	lnet.subscribe(tostring(self), callback)
end

--host selector
local function nexthost(list)--{{{
	local n = math.random(#list)
	return assert(list[n])
end--}}}


return function(conf)
	assert(#conf > 0, 'empty mongodb host list')
	local obj = mt_driver.new()
	local adb = obj:getdb(conf.adb or 'admin')
	assert(obj.c:open(nexthost(conf)), 'connect mongodb failed')
	assert(adb:authenticate(conf), 'authenticate to mongodb failed')
	obj.c:setopt('keepalive', conf.ti_ping, conf.ti_recv)
	obj.c:panic(function()
		lnet.send(tostring(obj), false)
		while not obj.c:open(nexthost(conf)) or not adb:authenticate(conf) do
			lnet.sleep(1)
		end
		obj.c:recover()
		lnet.send(tostring(obj), true)
	end)
	return obj
end

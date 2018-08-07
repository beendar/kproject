local assert = assert
local ipairs = ipairs
local sockdriver = require 'lnet.sockdriver'

--!@brief: dns contants
local MAX_DOMAIN_LEN = 1024
local MAX_LABEL_LEN  = 63
local DNS_HEADER_LEN = 12
local HOST           = sockdriver.dnshost()
local PORT           = 0x0035
local TIMEOUT        = 10

local QTYPE = {	A = 1 }
local QCLASS = { IN = 1 }

--!@brief: numeric decoding
local function decode_int8(packet, pos)--{{{
	return packet:byte(pos), pos + 1
end--}}}

local function decode_int16(packet, pos)--{{{
	local h8bit, l8bit = packet:byte(pos, pos+1)
	return h8bit*256 + l8bit, pos + 2
end--}}}

local function decode_int32(packet, pos)--{{{
	local a1,a2,a3,a4 = packet:byte(pos, pos+3)
	return a1*256^3 + a2*256^2 + a3*256 + a4, pos + 4
end--}}}

--!@brief: utility functions
local function verify_domain_name(name)--{{{
	if #name > MAX_DOMAIN_LEN then
		return false
	end
	if not name:match("^[_%l%d%-%.]+$") then
		return false
	end
	for w in name:gmatch("([_%w%-]+)%.?") do
		if #w > MAX_LABEL_LEN then
			return false
		end
	end
	return true
end--}}}

local next_tid = 1
local function gen_tid()--{{{
	local tid = next_tid
	next_tid = next_tid + 1
	return tid
end--}}}

local function pack_header(t)--{{{
	return string.char(
		t.tid % 256, math.floor(t.tid/256),			--id
		math.floor(t.flags/256), t.flags%256,		--flags
		math.floor(t.qdcount/256), t.qdcount%256,	--qdcount big-endian
		0, 0,	                                    --ancount
		0, 0,                                       --nscount
		0, 0)	                                    --arcount
end--}}}

local function pack_question(name, qtype, qclass)--{{{
	if not name:find'%.' then
		return
	end
	local labels = {}
	for w in name:gmatch('[^%.]+') do
		table.insert(labels, ('%c%s'):format(#w, w))
	end
	table.insert(labels, '\0')
	table.insert(labels, string.char(math.floor(qtype/256), qtype%256))
	table.insert(labels, string.char(math.floor(qclass/256), qclass%256))
	return table.concat(labels)
end--}}}

local function unpack_header(chunk)--{{{
	local tid = chunk:byte(1,1) + chunk:byte(2,2)*256
	local flags = decode_int16(chunk, 3)
	local qdcount = decode_int16(chunk, 5)
	local ancount = decode_int16(chunk, 7)
	return {
		tid = tid,
		flags = flags,
		qdcount = qdcount,
		ancount = ancount
	}
end--}}}

local function unpack_name(chunk, left)--{{{
	local encoded_len = 0
	local label_len = decode_int8(chunk, left)
	while label_len ~= 0 do
		--normal format
		if math.floor(label_len/0x3f) == 0 then
			encoded_len = encoded_len + label_len + 1
			left = left + label_len + 1
			label_len = decode_int8(chunk, left)
		--compressed format
		else
			return encoded_len + 2
		end
	end
	return encoded_len + 1
end--}}}

local function unpack_question(chunk, left)--{{{
	left = left + unpack_name(chunk, left)
	local atype, left = decode_int16(chunk, left)
	local class, left = decode_int16(chunk, left)
	return {
		atype = atype,
		class = class,
	}, left
end--}}}

local function unpack_answer(chunk, left)--{{{
	left = left + unpack_name(chunk, left)

	local atype, left    = decode_int16(chunk, left)
	local class, left    = decode_int16(chunk, left)
	local ttl, left      = decode_int32(chunk, left)
	local rdatalen, left = decode_int16(chunk, left)

	return {
		atype = atype,
		class = class,
		ttl = ttl,
		rdata = chunk:sub(left, left + rdatalen - 1)
	}, left + rdatalen
end--}}}

local function unpack_rdata(qtype, chunk)--{{{
	if qtype == QTYPE.A then
		local a,b,c,d = chunk:byte(1, 4)
		return string.format('%d.%d.%d.%d', a,b,c,d)
	end
end--}}}

local function _resolve(chunk)--{{{
	local left = DNS_HEADER_LEN + 1
	if (not chunk) or #chunk < DNS_HEADER_LEN then
		return nil, 'dns: recv an invalid dns packet when query'
	end
	local answer_header = unpack_header(chunk)
	if answer_header.qdcount ~= 1 then
		return nil, 'dns: recv an malformed packet'
	end
	if answer_header.ancount <= 0 then
		return nil, 'dns: none answer in packet'
	end
	local question
	for n=1, answer_header.qdcount do
		question, left = unpack_question(chunk, left)
	end
	local answer
	local answers = {}
	for n=1, answer_header.ancount do
		answer, left = unpack_answer(chunk, left)
		local ipaddr = unpack_rdata(answer.atype, answer.rdata)
		if ipaddr then
			table.insert(answers, ipaddr)
		end
	end
	return answers
end--}}}

local cache   = {}
local function lookup_cache(name)--{{{
	local answers = cache[name]
	if answers then
		return answers
	end
end--}}}

local function is_numeric_address(name)--{{{
	return (not name:find'[^%d%.]')
end--}}}


local function resolve(name)--{{{
	if is_numeric_address(name) then
		return name
	end
	local cached_answers = lookup_cache(name)
	if cached_answers then
		return cached_answers[1]
	end
	assert(verify_domain_name(name), 'dns: illegal domain name')
	local question_header = pack_header {
		tid = gen_tid(),
		flags = 0x0100,
		qdcount = 1
	}
	local question = pack_question(name, QTYPE.A, QCLASS.IN)
	local fd = assert(sockdriver.udp'0', 'dns: create socket failed')
	sockdriver.setopt(fd, 'datatype', 1)
	sockdriver.setopt(fd, 'recvtimeout', TIMEOUT)
	sockdriver.sendto(fd, HOST, PORT, question_header..question)
	local chunk = sockdriver.recvfrom(fd)
	sockdriver.close(fd)
	if not chunk then
		return nil, 'dns: socket error occurred when recv data'
	end
	local answers, err = _resolve(chunk)
	local addr
	if answers then
		addr = answers[1]
		cache[name] = answers
	end
	return addr, err
end--}}}


return {
	resolve = resolve
}
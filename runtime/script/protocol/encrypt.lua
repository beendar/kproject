local band     = require 'bit'.band
local bxor     = require 'bit'.bxor
local checksum = require 'crypt'.checksum


local function sign(secret, msg, len)
    local sum = checksum(msg, len)
	return bxor(secret, band(secret, sum))
end

local function validate(value, secret, msg, len)
	return (value>0 and secret>0 and value==sign(secret,msg,len))
end


return {
    sign = sign,
    validate = validate,
}

local function startup()
    require 'protocol.load'
    require 'cluster.slave'.newservice'manager'
end 

return {
    startup = startup
}
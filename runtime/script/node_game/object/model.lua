local archivesys = require 'gamesys.archive'


-- input parameters
local pid,rgnid = ...

-- user game archive
local archive = archivesys.load(pid, rgnid)

---@class model
local inst = {
	pid = pid,
	rgnid = rgnid,
	archive = archive,
}

---@ special table, execute callback when drop a key
local envar = table.keysensi(inst)


-- 系统级接口
function inst:start()

	-- 更新上线时间
	archive.base.online = os.time()

	-- 集中完成其余逻辑模块所需上线更新
	require'gamesys.update'.online(self)

	-- 落地
    self:save()
end

function inst:stop()

	-- 清理未落地的脏数据
	for _,sy in pairs(archive) do
		sy:clear()
	end

	-- 更新下线时间
	archive.base.offline = os.time()

	-- 集中完成其余逻辑模块所需下线更新
	require'gamesys.update'.offline(self)

	-- 清除其余模块安装的会话环境变量
	envar:clear()

	-- 落地
    self:save()
end

function inst:save()
	for _,sy in pairs(archive) do
		sy:save()
	end
end


-- 业务级接口
function inst:gensn()
	local sn = archive.base.gensn + 1
	archive.base.gensn = sn
	return sn
end

function inst:genmailid()
	return ('u%s:%d'):format(pid, self:gensn())
end

function inst:getvar(key)
	return envar:get(key)
end

function inst:setvar(key, value, on_dropkey)
	envar:set(key, value, on_dropkey)
end

function inst:delvar(key)
	return envar:drop(key)
end


return setmetatable(inst, { __index = function( _, colname )
	-- lazy loading single instance or creating multiple instance loader
	local loader = archivesys.ismultiple(colname) and 'gameobject.mloader' or 'gameobject.sloader'
	inst[colname] = require(loader).load(colname, inst)
	return inst[colname]
end})

local setmetatable = setmetatable
local table = table
local math = math

module 'minheap'

local minheap = {}
minheap.__index = minheap


function minheap.new()
  local o = {}   
  setmetatable(o, minheap)
  o.m_size = 0
  o.m_data = {}
  return o
end


function minheap:up(index)
    local parent_idx = self:parent(index)
    while parent_idx > 0 do
        if self.m_data[index].value < self.m_data[parent_idx].value then
            self:swap(index,parent_idx)
            index = parent_idx
            parent_idx = self:parent(index)
        else
            break
        end
    end
end

function minheap:down(index)
    local l = self:left(index)
    local r = self:right(index)
    local min = index

    if l <= self.m_size and self.m_data[l].value < self.m_data[index].value then
        min = l
    end

    if r <= self.m_size and self.m_data[r].value < self.m_data[min].value then
        min = r
    end

    if min ~= index then
        self:swap(index,min)
        self:down(min)
    end
end

function minheap:parent(index)
    local parent = math.modf(index/2)
    return parent
end

function minheap:left(index)
    return 2*index
end

function minheap:right(index)
    return 2*index + 1
end



function minheap:change(co)
    local index = co.index
    if index == 0 then
        return
    end
    self:down(index)
    if index == co.index then
	self:up(index)
    end
end

function minheap:insert(co)
    if co.index ~= 0 then
        return
    end
    self.m_size = self.m_size + 1
    table.insert(self.m_data,co)
    co.index = self.m_size
    self:up(self.m_size)
end

function minheap:min()
    if self.m_size == 0 then
        return nil
    end
    return self.m_data[1]
end

function minheap:popmin()
    local co = self.m_data[1]
    self:swap(1,self.m_size)
    self.m_data[self.m_size] = nil
    self.m_size = self.m_size - 1
    self:down(1)
    co.index = 0
    return co
end

function minheap:size()
    return self.m_size
end

function minheap:swap(idx1,idx2)
    local tmp = self.m_data[idx1]
    self.m_data[idx1] = self.m_data[idx2]
    self.m_data[idx2] = tmp

    self.m_data[idx1].index = idx1
    self.m_data[idx2].index = idx2
end

function minheap:clear()
    while m_size > 0 do
        self:popmin()
    end
    self.m_size = 0
end

function minheap:remove(co)
    if co.index > 0 then
        if self.m_size > 1 then
            local index = co.index
            local other = self.m_data[self.m_size]
            self:swap(index,self.m_size)
            self.m_data[self.m_size] = nil
            self.m_size = self.m_size - 1
            self:down(other.index)      
        else
            self.m_data[self.m_size] = nil
            self.m_size = self.m_size - 1           
        end
        co.index = 0
    end
end


function new()
    return minheap.new()
end
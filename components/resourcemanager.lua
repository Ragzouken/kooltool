local Class = require "hump.class"

local Queue = Class {}

function Queue:init()
    self.first = nil
    self.last  = nil
    self.items = {}
end

function Queue:push(item)
    if not self.first then
        self.first, self.last = 1, 1
    else
        self.last = self.last + 1
    end

    self.items[self.last] = item
end

function Queue:pop()
    if not self.first then
        return nil
    end

    local item = self.items[self.first]

    if self.first == self.last then
        self.first, self.last = nil, nil
    else
        self.first = self.first + 1
    end

    return item
end

function Queue:consume()
    return coroutine.wrap(function()
        while self.first ~= nil do
            coroutine.yield(self:pop())
        end
    end)
end

local ResourceManager = Class {}

function ResourceManager:init()
    self.count = 0
    self.id_to_resource = {}
    self.resource_to_id = {}
    self.resources = Queue()
end

function ResourceManager:new_id()
    self.count = self.count + 1

    return self.count
end

function ResourceManager:reference(resource)
    return self.resource_to_id[resource] or self:register(resource)
end

function ResourceManager:register(resource)
    assert(not self.resource_to_id[resource])

    local id = self:new_id()
    local reference = {resource.name, id, resource}

    self.resource_to_id[resource] = id
    self.id_to_resource[id] = resource

    self.resources:push(resource)

    return id
end

function ResourceManager:test()
    for resource in self.resources:consume() do
        --resource:testser(self)
        print(self.resource_to_id[resource], resource.name)
    end
end

return ResourceManager

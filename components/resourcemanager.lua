local Class = require "hump.class"
local json = require "utilities.dkjson"

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

function ResourceManager:init(root, ...)
    self.root = root
    self.types = {}

    for i, class in ipairs{...} do
        self.types[class.type or "INVALID"] = class
    end

    self.count = 0
    self.id_to_resource = {}
    self.resource_to_id = {}
    self.resources = Queue()
    self.labels = {}
end

function ResourceManager:new_id(resource)
    self.count = self.count + 1

    return string.format("%d-%s", self.count, resource.type)
end

function ResourceManager:reference(resource)
    return self.resource_to_id[resource] or self:register(resource)
end

function ResourceManager:resource(reference)
    return self.id_to_resource[reference]
end

function ResourceManager:register(resource, params)
    assert(not self.resource_to_id[resource])

    params = params or {}

    local id = params.id or self:new_id(resource)
    local reference = {resource.name, id, resource}

    self.resource_to_id[resource] = id
    self.id_to_resource[id] = resource

    self.resources:push(resource)

    if params.label then
        self.labels[params.label] = id
    end

    return id
end

function ResourceManager:file(resource, name)
    local file = string.format("%s_%s", self.resource_to_id[resource], name)
    local full = self.root .. "/" .. file

    return full, file
end

function ResourceManager:path(file)
    return self.root .. "/" .. file
end

function ResourceManager:save()
    love.filesystem.createDirectory(self.root)

    for resource in self.resources:consume() do
        local data = {
            type = resource.type,
            data = resource:serialise(self)
        }

        local name = string.format("%s.json", self.resource_to_id[resource])

        local file = love.filesystem.newFile(self.root .. "/" .. name, "w")
        file:write(json.encode(data, { indent = true, }))
        file:close()

        print("saving", resource.name, "to", name)
    end

    local index = {
        files = {},
        labels = self.labels,
    }

    for id, resource in pairs(self.id_to_resource) do
        index.files[id] = string.format("%s.json", id)
    end

    local file = love.filesystem.newFile(self.root .. "/index.json", "w")
    file:write(json.encode(index, { indent = true, }))
    file:close()
end

function ResourceManager:load()
    local content = love.filesystem.read(self.root .. "/index.json")
    local index = json.decode(content)

    local data = {}

    for id, path in pairs(index.files) do
        local content = love.filesystem.read(self.root .. "/" .. path)
        local wrapped = json.decode(content)

        local type = wrapped.type and self.types[wrapped.type]

        if type then
            local resource = type()
            self:register(resource, { id = id, })
            data[resource] = wrapped.data
        else
            print("DESERIALISATION: no matching type (" .. tostring(wrapped.type) .. ") for " .. path)
        end
    end

    for label, id in pairs(index.labels) do
        self.labels[label] = self:resource(id)
    end

    for resource, data in pairs(data) do
        resource:deserialise(self, data)
    end

    for resource, data in pairs(data) do
        resource:finalise(self, data)
    end
end

return ResourceManager

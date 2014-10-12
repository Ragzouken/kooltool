local Class = require "hump.class"
local Collider = require "collider"
local SurfaceLayer = require "layers.surface"
local AnnotationLayer = require "layers.annotation"

local Sprite = require "components.sprite"
local Entity = require "components.entity"
local Notebox = require "components.notebox"

local generators = require "generators"
local common = require "utilities.common"
local export = require "utilities.export"
local colour = require "utilities.colour"

local json = require "utilities.dkjson"

local ResourceManager = Class {}

function ResourceManager:serialise(saves)
    local resources = {}

    for index, resource in pairs(self.index_to_resource) do
        resources[index] = resource:serialise(saves)
    end

    return resources
end

function ResourceManager:deserialise(data, saves)
    for index, data in pairs(data) do
        local instance = self.class()
        instance:deserialise(data, saves)

        self:add(instance, index)
    end
end

function ResourceManager:init(class)
    self.class = class
    
    self.index_to_resource = {}
    self.resource_to_index = {}

    self.next_index = 1
end

function ResourceManager:new(...)
    local resource = class(...)

    self.index_to_resource[self.next_index] = resource
    self.resource_to_index[resource] = self.next_index

    self.next_index = self.next_index + 1

    return resource
end

function ResourceManager:add(resource, index)
    self.index_to_resource[index] = resource
    self.resource_to_index[resource] = index

    self.next_index = math.max(index + 1, self.next_index)
end

function ResourceManager:remove(resource)
    local index = self.resource_to_index[resource]

    self.index_to_resource[index] = nil
    self.resource_to_index[resource] = nil
end

local Project = Class {}

do
    local names = {}

    for line in love.filesystem.lines("texts/names.txt") do
        names[#names+1] = line
    end

    Project.name_generator = generators.String(names)
end

function Project:serialise(saves)
    local data = {}

    data.name = self.name
    data.description = self.description

    --[[
    data.resources = {}

    for name, manager in pairs(self.resources) do
        data.resources[name] = manager:serialise(saves .. "/" .. name) 
    end
    ]]

    return data
end

function Project:deserialise(data, saves)
    self.name = data.name
    self.description = data.description

    --[[
    for name, manager in pairs(self.resources) do
        manager:deserialise(data.resources[name], saves .. "/" .. name)
    end
    ]]
end

local broken = love.graphics.newImage("images/broken.png")

function Project:blank(tilesize)
    self.icon = broken

    self.palette = PALETTE
    self.layers.surface = generators.surface.default(self, tilesize)
    self.layers.annotation = AnnotationLayer(self)

    self.description = "yr new project"
end

function Project:init(name)
    self.name = name:match("[^/]+$")

    self.resources = {
        sprites = ResourceManager(Sprite),
    }

    self.layers = {}
    
    self.description = "[NO DESCRIPTION]"
end

function Project:loadIcon(folder_path)
    local file = folder_path .. "/icon.png"

    if not pcall(function() self.icon = common.loadCanvas(file) end) then
        self.icon = broken
    end
end

function Project:preview(folder_path)
    local file = love.filesystem.read(folder_path .. "/details.json")
    
    if file then
        local data = json.decode(file)
        self:deserialise(data, folder_path)
    end

    self:loadIcon(folder_path)
end

function Project:load(folder_path)
    if self.name == "tutorial" then self.name = "tutorial_copy" end

    local file = love.filesystem.read(folder_path .. "/details.json")
    
    if file then
        local data = json.decode(file)
        self:deserialise(data, folder_path)
    end

    local file = love.filesystem.read(folder_path .. "/tilelayer.json")
    local data = json.decode(file)
    self.layers.surface = SurfaceLayer(self)
    self.layers.surface:deserialise(data, folder_path)

    local data = love.filesystem.read(folder_path .. "/notelayer.json")
    self.layers.annotation = AnnotationLayer(self)
    self.layers.annotation:deserialise(json.decode(data), folder_path)
end

function Project:save(folder_path)
    love.filesystem.createDirectory(folder_path)
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.layers.surface:serialise(folder_path), { indent = true, }))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.layers.annotation:serialise(folder_path), { indent = true, }))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/details.json", "w")
    file:write(json.encode(self:serialise(folder_path), { indent = true, }))
    file:close()

    self.layers.surface:exportRegions(folder_path)
end

function Project:update(dt)
    self.layers.surface:update(dt)
    self.layers.annotation:update(dt)

    colour.cursor(dt)
    colour.walls(dt, 0)
end

function Project:draw(annotations, play)
    self.layers.surface:draw()

    if EDITOR.active ~= EDITOR.tools.draw and not play then
        for entity in pairs(self.layers.surface.entities) do
            entity:border()
        end
    end

    if annotations then self.layers.annotation:draw() end
end

function Project:objectAt(x, y)
    local entity = self.layers.surface:objectAt(x, y)
    local notebox = self.layers.annotation:objectAt(x, y)

    return notebox or entity
end

function Project:sample(x, y)
end

function Project:newEntity(x, y)
    local entity = Entity(self.layers.surface)
    entity:blank(x, y)

    self.layers.surface:addEntity(entity)

    return entity
end

function Project:undo()
--local action = table.remove(self.history)
--if action then action() end
end

Project.export = export.export

return Project

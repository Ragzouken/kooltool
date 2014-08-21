local Class = require "hump.class"
local Collider = require "collider"
local History = require "history"
local SurfaceLayer = require "layers.surface"
local AnnotationLayer = require "layers.annotation"

local Entity = require "entity"
local Notebox = require "notebox"

local generators = require "generators"
local common = require "common"
local export = require "export"
local colour = require "colour"

require "utilities.json" -- ugh

local Project = Class {}

do
    local names = {}

    for line in love.filesystem.lines("texts/names.txt") do
        names[#names+1] = line
    end

    Project.name_generator = generators.String(names)
end

function Project.default(name)
    local project = Project(name)

    project.palette = PALETTE
    project.layers.surface = generators.surface.default(project)
    project.layers.annotation = AnnotationLayer(project)
    
    return project
end

function Project:init(name)
    self.name = name:match("[^/]+$")

    self.dragables = Collider(128)

    self.layers = {}
    self.history = History()
end

function Project:load(folder_path)
    if self.name == "tutorial" then self.name = "tutorial_copy" end

    local data = love.filesystem.read(folder_path .. "/tilelayer.json")
    self.layers.surface = SurfaceLayer(self)
    self.layers.surface:deserialise(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/entitylayer.json")
    self.layers.surface:deserialise_entity(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/notelayer.json")
    self.layers.annotation = AnnotationLayer(self)
    self.layers.annotation:deserialise(json.decode(data), folder_path)
end

function Project:save(folder_path)
    love.filesystem.createDirectory(folder_path)
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.layers.surface:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.layers.annotation:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/entitylayer.json", "w")
    file:write(json.encode(self.layers.surface:serialise_entity(folder_path)))
    file:close()

    self.layers.surface:exportRegions(folder_path)
end

function Project:loadIcon(folder_path)
    local file = folder_path .. "/icon.png"

    if not pcall(function() self.icon = common.loadCanvas(file) end) then
        self.icon = love.graphics.newCanvas(32, 32)
    end
end

function Project:update(dt)
    self.layers.surface:update(dt)
    self.layers.annotation:update(dt)

    colour.cursor(dt)
    colour.walls(dt, 0)
end

function Project:draw(annotations)
    self.layers.surface:draw()

    if INTERFACE_ and INTERFACE_.active ~= INTERFACE_.tools.draw then
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

    table.insert(self.history, function()
        self.layers.surface:removeEntity(entity)
    end)

    return entity
end

function Project:newNotebox(x, y)
    local notebox = Notebox(self.layers.annotation, x, y, "[note]")
    self.layers.annotation:addNotebox(notebox)

    table.insert(self.history, function()
        self.layers.annotation:removeNotebox(notebox)
    end)

    return notebox
end

function Project:undo()
    --local action = table.remove(self.history)
    --if action then action() end
end

Project.export = export.export

return Project

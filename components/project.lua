local Class = require "hump.class"
local Collider = require "collider"
local SurfaceLayer = require "layers.surface"
local AnnotationLayer = require "layers.annotation"

local Sprite = require "components.sprite"
local Entity = require "components.entity"
local Notebox = require "components.notebox"
local Tileset = require "components.tileset"

local generators = require "generators"
local common = require "utilities.common"
local export = require "utilities.export"
local colour = require "utilities.colour"

local json = require "utilities.dkjson"

local ResourceManager = require "components.resourcemanager"

local Project = Class {
    type = "Project",
}

do
    local names = {}

    for line in love.filesystem.lines("texts/names.txt") do
        names[#names+1] = line
    end

    Project.name_generator = generators.String(names)
end

function Project:serialise(resources)
    local data = {}

    data.name = self.name
    data.description = self.description

    data.layers = {
        surface    = resources:reference(self.layers.surface),
        annotation = resources:reference(self.layers.annotation),
    }

    return data
end

function Project:deserialise(resources, data)
    self.name = data.name
    self.description = data.description

    self.layers = {
        surface    = resources:resource(data.layers.surface),
        annotation = resources:resource(data.layers.annotation),
    }
end

local broken = love.graphics.newImage("images/broken.png")

function Project:blank(tilesize)
    self.icon = broken

    self.palette = PALETTE
    self.layers.surface = generators.surface.default(self, tilesize)
    self.layers.annotation = AnnotationLayer(self)

    self.description = "yr new project"
end

function Project:init()
    self.name = "unnamed"
    self.description = "[NO DESCRIPTION]"

    self.layers = {}
end

function Project:finalise()
end

function Project:load(folder_path)
    if self.name == "tutorial" then self.name = "tutorial_copy" end

    --[[
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
    ]]

    local resources = ResourceManager(Project,
                                      SurfaceLayer,
                                      AnnotationLayer,
                                      Sprite,
                                      Entity,
                                      Tileset)

    resources:load(folder_path)

    return resources.labels.project
end

function Project:save(folder_path)
    local resources = ResourceManager()

    love.filesystem.createDirectory(folder_path)
    --[[
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.layers.surface:serialise(folder_path), { indent = true, }))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.layers.annotation:serialise(folder_path), { indent = true, }))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/details.json", "w")
    file:write(json.encode(self:serialise(folder_path, resources), { indent = true, }))
    file:close()
    ]]

    resources:register(self, { label = "project" } )
    resources:save(folder_path)
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
        if data then 
            self.name = data.name
            self.description = data.description
        end
    end

    self:loadIcon(folder_path)
end

function Project:update(dt)
    self.layers.surface:update(dt)
    self.layers.annotation:update(dt)

    colour.cursor(dt)
    colour.walls(dt, 0)
end

function Project:draw(annotations, play)
    self.layers.surface:draw()

    if not play and EDITOR.active ~= EDITOR.tools.draw and not play then
        for entity in pairs(self.layers.surface.entities) do
            entity:border()
        end
    end

    if annotations then self.layers.annotation:draw() end
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

local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local ResourceManager = require "saving.resourcemanager"

local generators = require "generators"
local common = require "utilities.common"
local colour = require "utilities.colour"

local Project = Class {
    __includes = Panel,
    name = "Generic Project",
    type = "Project",

    gridsize = {32, 32},
    description = "[NO DESCRIPTION]",
}

function Project:serialise(resources)
    local data = {}

    data.name = self.name
    data.description = self.description
    data.gridsize = self.gridsize

    data.annotation = resources:reference(self.annotation)
    data.layers = {}
    data.sprites = {}
    data.regions = {}

    for i, layer in ipairs(self.layers) do
        data.layers[i] = resources:reference(layer)
    end

    for sprite in pairs(self.sprites) do
        table.insert(data.sprites, resources:reference(sprite))
    end

    for i, region in ipairs(self.regions) do
        table.insert(data.regions, resources:reference(region))
    end

    return data
end

function Project:deserialise(resources, data)
    self.name = data.name
    self.description = data.description
    self.gridsize = data.gridsize or {32, 32}

    self.annotation = resources:resource(data.annotation)
    self:add(self.annotation, -math.huge)

    for i, layer in ipairs(data.layers) do
        self:add_layer(resources:resource(layer))
    end

    for i, sprite in ipairs(data.sprites) do
        self:add_sprite(resources:resource(sprite))
    end

    for i, region in ipairs(data.regions) do
        self.regions[i] = resources:resource(region)
    end

    self.palette = generators.Palette.generate(9, 9)
end

function Project:init(path)
    Panel.init(self)

    self.path = path
    self.name = "unnamed"
    self.description = "[NO DESCRIPTION]"
    self.gridsize = {32, 32}

    self.layers = {}
    self.sprites = {}
    self.regions = {}
end

function Project:finalise()
end

function Project:load()
    local resources = ResourceManager(self.path,
                                      require "components.project",
                                      require "components.tileset",
                                      require "components.sprite",
                                      require "components.entity",
                                      require "layers.annotation",
                                      require "layers.scripting",
                                      require "components.infinite-canvas",
                                      require "components.tilemap",
                                      require "layers.world",
                                      require "components.region")

    resources:load()

    local project = resources.labels.project

    project.path = self.path
    project:preview()

    return project
end

function Project:save(folder_path)
    local resources = ResourceManager(folder_path)

    resources:register(self, { label = "project" } )
    resources:save(folder_path)
end

local broken = love.graphics.newImage("images/broken.png")

function Project:preview()
    local resources = ResourceManager(self.path)
    local meta = resources:meta()

    self.name = meta.name or self.name
    self.description = meta.description or self.description

    if not pcall(function() self.icon = common.loadCanvas(resources:path(meta.icon)) end) then
        self.icon = common.canvasFromImage(broken)
    end
end

function Project:update(dt)
    self.annotation:update(dt)

    for i, layer in ipairs(self.layers) do
        layer:update(dt)
    end

    colour.cursor(dt)
    colour.walls(dt, 0)
end

function Project:export()
    export.export(self.name)
end

function Project:add_sprite(sprite)
    self.sprites[sprite] = true
end

function Project:add_layer(layer)
    table.insert(self.layers, layer)

    self:add(layer)
end

return Project

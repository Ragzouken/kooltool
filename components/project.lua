local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local ResourceManager = require "components.resourcemanager"

local generators = require "generators"
local common = require "utilities.common"
local export = require "utilities.export"
local colour = require "utilities.colour"

local Project = Class {
    __includes = Panel,
    name = "Generic Project",
    type = "Project",
}

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

    self:add(self.layers.surface, -1)
    self:add(self.layers.annotation, -2)

    self.palette = generators.Palette.generate(9)
end

function Project:init(path)
    Panel.init(self)

    self.path = path
    self.name = "unnamed"
    self.description = "[NO DESCRIPTION]"

    self.layers = {}
end

function Project:finalise()
end

function Project:load()
    local resources = ResourceManager(self.path,
                                      require "components.project",
                                      require "components.tileset",
                                      require "components.sprite",
                                      require "components.entity",
                                      require "layers.surface",
                                      require "layers.annotation",
                                      require "layers.scripting")

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
    self.layers.surface:update(dt)
    self.layers.annotation:update(dt)

    colour.cursor(dt)
    colour.walls(dt, 0)
end

Project.export = export.export

return Project

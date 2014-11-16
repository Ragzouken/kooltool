local StringGenerator = require "generators.string"

local broken = love.graphics.newImage("images/broken.png")

local project = {}

do
    local names = {}

    for line in love.filesystem.lines("texts/names.txt") do
        names[#names+1] = line
    end

    local generator = StringGenerator(names)

    project.name = function() return generator:generate() end
end

function project.default(tilesize)
    local common = require "utilities.common"
    local Project = require "components.project"
    local AnnotationLayer = require "layers.annotation"
    local generators = require "generators"

    local project_ = Project()

    project_.icon = common.canvasFromImage(broken)
    project_.name = project.name():gsub(" ", "_")
    project_.description = "yr new project"

    project_.palette = generators.Palette.generate(9)
    project_.layers.surface = generators.surface.default(project_, tilesize)
    project_.layers.annotation = AnnotationLayer(project_)

    project_:add(project_.layers.surface)
    project_:add(project_.layers.annotation)

    return project_
end

return project

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

function project.default(gridsize)
    local common = require "utilities.common"
    local Project = require "components.project"
    local AnnotationLayer = require "layers.annotation"
    local generators = require "generators"
    local Region = require "components.region"

    local project_gen = project
    local project = Project()

    project.icon = common.canvasFromImage(broken)
    project.name = project_gen.name():gsub(" ", "_")
    project.description = "yr new project"
    project.gridsize = gridsize

    project.palette = generators.Palette.generate(16, 16)

    --project.annotation = AnnotationLayer(project)
    --project:add(project.annotation, -math.huge)

    project:add_layer(generators.world.default(project))

    local region = Region(project)
    region.name = "Wall"
    region.colour = {255, 0, 0, 192}

    project.regions[1] = region

    return project
end

return project

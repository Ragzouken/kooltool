local Tileset = require "components.tileset"
local Brush = require "brush"

local tileset = {}

function tileset.flat(project)
    local generators = require "generators"

    local tileset = Tileset()

    tileset:applyBrush(tileset:add_tile(), Brush(32, 32, function()
        love.graphics.setColor(project.palette.colours[1])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end))

    tileset:applyBrush(tileset:add_tile(), Brush(32, 32, function()
        love.graphics.setColor(project.palette.colours[2])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end))

    return tileset
end

return tileset

local Tileset = require "components.tileset"
local Brush = require "tools.brush"

local tileset = {}

function tileset.flat(project, tilesize)
    local generators = require "generators"

    local w, h = unpack(tilesize)

    local tileset = Tileset(tilesize)

    tileset:applyBrush(tileset:add_tile(), Brush(w, h, function()
        love.graphics.setColor(project.palette.colours[1])
        love.graphics.rectangle("fill", 0, 0, w, h)
    end))

    tileset:applyBrush(tileset:add_tile(), Brush(w, h, function()
        love.graphics.setColor(project.palette.colours[2])
        love.graphics.rectangle("fill", 0, 0, w, h)
    end))

    return tileset
end

return tileset

local Class = require "hump.class"
local SparseGrid = require "sparsegrid"

local TilePalette = Class {}

function TilePalette:init(x, y, tileset)
    self.x, self.y = x, y
    self.tileset = tileset
    self.grid = SparseGrid(32)
end

function TilePalette:draw()
    local size = 32

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.rectangle("fill", self.x - size / 2, self.y size / 2, 32, 32)
end

function TilePalette:mousepressed(x, y, button)
    x, y = x - self.x, y - self.x
end

function TilePalette:mousereleased(x, y, button1)
end

return TilePalette

local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local colour = require "utilities.colour"

local Tilebar = Class {
    __includes = Panel,
}

function Tilebar:init(interface)
    Panel.init(self)

    self.interface = interface
    self.tileset = self.interface.project.layers.surface.tileset
end

function Tilebar:draw()
    local margin = 4
    local edge = love.graphics.getWidth()

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode("alpha")
    love.graphics.rectangle("fill", edge-margin-1-32, margin-1, 32+2, self.tileset.tiles*(32+1)+1)

    love.graphics.setBlendMode("premultiplied")
    for i, quad in ipairs(self.tileset.quads) do
        local x, y = edge - 32 - margin, margin + (i - 1) * (32 + 1)

        love.graphics.draw(self.tileset.canvas, quad, edge-32-margin, margin + (i-1) * 33)
    end

    local TILE = self.interface.tools.tile.tile
    local x, y = edge - 32 - margin, margin + (TILE - 1) * (32 + 1)
    love.graphics.setColor(colour.cursor(0))
    love.graphics.rectangle("line", x, y, 32, 32)
end

function Tilebar:mousepressed(button, sx, sy, wx, wy)
    return self:click(button, sx, sy)
end

function Tilebar:click(button, x, y)
    local margin = 4
    local edge = love.graphics.getWidth()

    if x > edge-32-margin and y > margin and x < edge-margin then
        local i = math.floor((y - margin) / 33) + 1
        
        if i <= self.tileset.tiles then
            self.interface.active = self.interface.tools.tile
            self.interface.tools.tile.tile = i
            return true
        end
    end
end

return Tilebar

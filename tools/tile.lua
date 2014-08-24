local Class = require "hump.class"
local Tool = require "tools.tool"

local bresenham = require "utilities.bresenham"
local colour = require "utilities.colour"

local Tile = Class {
    __includes = Tool,
    name = "tile",
    sound = love.audio.newSource("sounds/marker pen.wav"),
}

function Tile:init(project, tile)
    Tool.init(self)
    
    self.project = project
    self.tile = 1
end

function Tile:cursor(sx, sy, wx, wy)
    if self.drag or not self.project:objectAt(wx, wy) then
        local layer = self.project.layers.surface
        local gx, gy = layer.tilemap:gridCoords(wx, wy)
        local size = 32
        local quad = layer.tileset.quads[self.tile]

        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.draw(layer.tileset.canvas, quad, gx * size, gy * size)
        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*size, gy*size, size, size)
    end
end

function Tile:mousepressed(button, sx, sy, wx, wy)
    if button == "l" then
        if love.keyboard.isDown("lalt") then
            local layer = self.project.layers.surface
            local gx, gy = layer.tilemap:gridCoords(wx, wy)
            self.tile = layer:getTile(gx, gy) or self.tile

            return true
        else
            if self.project:objectAt(wx, wy) then return false end

            self:startdrag("draw")

            return true, "begin"
        end
    elseif self.drag and button == "r" then
        self.drag.erase = true

        return true
    end
end

function Tile:mousedragged(action, screen, world)
    if action == "draw" then
        local layer = self.project.layers.surface
        local wx, wy, dx, dy = unpack(world)

        local x1, y1 = layer.tilemap:gridCoords(wx-dx, wy-dy)
        local x2, y2 = layer.tilemap:gridCoords(wx, wy)

        local change = false
        local index = not self.drag.erase and self.tile or nil

        for lx, ly in bresenham.line(x1, y1, x2, y2) do
            change = layer:setTile(index, lx, ly) or change
        end

        if change then
            self.sound:stop()
            self.sound:play()
        end
    end
end

function Tile:mousereleased(button, sx, sy, wx, wy)
    if button == "l" or (self.drag and button == "r") then
        self:enddrag()

        return true, "end"
    end
end

return Tile

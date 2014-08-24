local Class = require "hump.class"
local Tool = require "tools.tool"

local bresenham = require "utilities.bresenham"
local colour = require "utilities.colour"

local Wall = Class {
    __includes = Tool,
    name = "walls",
    sound = love.audio.newSource("sounds/marker pen.wav"),
}

function Wall:init(project, tile)
    Tool.init(self)
    
    self.project = project
    self.tile = 1
end

function Wall:cursor(sx, sy, wx, wy)
    local size = 32
    local layer = self.project.layers.surface

    love.graphics.setBlendMode("alpha")

    for tile, gx, gy in layer.tilemap:items() do
        local wall = layer.wallmap:get(gx, gy)

        if wall == nil and layer.wall_index[tile[1]] then
            love.graphics.setColor(colour.walls(0, 0))
            love.graphics.rectangle("fill", gx * size, gy * size, size, size)
        end
    end

    for wall, gx, gy in layer.wallmap:items() do
        if wall then
            love.graphics.setColor(colour.walls(0, 0))
        else
            love.graphics.setColor(colour.walls(0, 85))
        end

        love.graphics.rectangle("fill", gx * size, gy * size, size, size)
    end

    if self.drag or not self.project:objectAt(wx, wy) then
        local gx, gy = layer.tilemap:gridCoords(wx, wy)
        local quad = layer.tileset.quads[self.tile]

        if self.drag and self.drag.erase then
            love.graphics.setColor(0, 255, 0, 128)
        else
            love.graphics.setColor(255, 0, 0, 128)
        end

        love.graphics.rectangle("fill", gx*size, gy*size, size, size)
        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*size, gy*size, size, size)
    end
end

function Wall:mousepressed(button, sx, sy, wx, wy)
    if button == "l" then
        if self.project:objectAt(wx, wy) then return false end

        self:startdrag("draw")

        return true, "begin"
    elseif self.drag and button == "r" then
        self.drag.erase = true

        return true
    end
end

function Wall:mousedragged(action, screen, world)
    if action == "draw" then
        local layer = self.project.layers.surface
        local wx, wy, dx, dy = unpack(world)

        local x1, y1 = layer.tilemap:gridCoords(wx-dx, wy-dy)
        local x2, y2 = layer.tilemap:gridCoords(wx, wy)

        local change = false
        local clone = love.keyboard.isDown("lctrl")

        for lx, ly in bresenham.line(x1, y1, x2, y2) do
            change = layer:setWall(not self.drag.erase, lx, ly, clone) or change
        end

        if change then
            self.sound:stop()
            self.sound:play()
        end
    end
end

function Wall:mousereleased(button, sx, sy, wx, wy)
    if button == "l" or (self.drag and button == "r") then
        self:enddrag()

        return true, "end"
    end
end

return Wall

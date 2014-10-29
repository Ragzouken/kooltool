local Class = require "hump.class"
local Tool = require "tools.tool"

local bresenham = require "utilities.bresenham"
local colour = require "utilities.colour"

local Wall = Class {
    __includes = Tool,
    name = "walls",
    sound = love.audio.newSource("sounds/marker pen.wav"),
}

function Wall:init(editor, project)
    Tool.init(self)
    
    self.editor = editor
    self.project = project
    self.tile = 1
end

function Wall:cursor(sx, sy, wx, wy)
    local target = self.editor:target("tile", sx, sy)

    if not target then return end

    local tw, th = unpack(target.tileset.dimensions)

    for tile, gx, gy in target.tilemap:items() do
        local wall = target.wallmap:get(gx, gy)

        if wall == nil and target.wall_index[tile[1]] then
            love.graphics.setColor(colour.walls(0, 0))
            love.graphics.rectangle("fill", gx * tw, gy * th, tw, th)
        end
    end

    for wall, gx, gy in target.wallmap:items() do
        if wall then
            love.graphics.setColor(colour.walls(0, 0))
        else
            love.graphics.setColor(colour.walls(0, 85))
        end

        love.graphics.rectangle("fill", gx * tw, gy * th, tw, th)
    end

    if self.drag or target then
        local gx, gy = target.tilemap:gridCoords(wx, wy)
        local quad = target.tileset.quads[self.tile]

        if self.drag and self.drag.erase then
            love.graphics.setColor(0, 255, 0, 128)
        else
            love.graphics.setColor(255, 0, 0, 128)
        end

        love.graphics.rectangle("fill", gx*tw, gy*th, tw, th)
        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*tw, gy*th, tw, th)
    end
end

function Wall:mousepressed(button, sx, sy, wx, wy)
    local target = self.editor:target("tile", sx, sy)

    if button == "l" and target then
        self:startdrag("draw")

        return true, "begin"
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
            change = layer:setWall(not love.keyboard.isDown("x", "e"), lx, ly, clone) or change
        end

        if change then
            self.sound:stop()
            self.sound:play()
        end
    end
end

function Wall:mousereleased(button, sx, sy, wx, wy)
    if button == "l" then
        self:enddrag()

        return true, "end"
    end
end

return Wall

local Class = require "hump.class"
local Tool = require "tools.tool"

local bresenham = require "utilities.bresenham"
local colour = require "utilities.colour"

local eraser = love.graphics.newImage("images/icons/eraser.png")

local Tile = Class {
    __includes = Tool,
    name = "tile",
    sound = love.audio.newSource("sounds/marker pen.wav"),
}

function Tile:init(editor, project, tile)
    Tool.init(self)
    
    self.editor = editor
    self.project = project
    self.tile = 1
end

function Tile:cursor(sx, sy, wx, wy)
    local target = self.editor:target("tile", sx, sy)

    if target then
        local gx, gy = target.tilemap:gridCoords(wx, wy)
        local tw, th = unpack(target.tileset.dimensions)
        local quad = target.tileset.quads[self.tile]

        love.graphics.setBlendMode("premultiplied")
        
        if self.tile then
            love.graphics.setColor(255, 255, 255, 128)
            love.graphics.draw(target.tileset.canvas, quad, gx * tw, gy * th)
        else
            local scale = math.min(tw, th) / 32

            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.draw(eraser, (gx + 0.5) * tw, (gy + 0.5) * th, 0, scale, scale, 16, 16)
        end

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*tw, gy*th, tw, th)
    end
end

function Tile:mousepressed(button, sx, sy, wx, wy)
    local target = self.editor:target("tile", sx, sy)

    if button == "l" and target then
        if love.keyboard.isDown("lalt") then
            local gx, gy = target.tilemap:gridCoords(wx, wy)
            self.tile = target:getTile(gx, gy) or self.tile

            return true
        else
            self:startdrag("draw")

            return true, "begin"
        end
    end
end

function Tile:mousedragged(action, screen, world)
    if action == "draw" then
        local layer = self.project.layers.surface
        local wx, wy, dx, dy = unpack(world)

        local x1, y1 = layer.tilemap:gridCoords(wx-dx, wy-dy)
        local x2, y2 = layer.tilemap:gridCoords(wx, wy)

        local change = false
        local index = self.tile

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
    if button == "l" then
        self:enddrag()

        return true, "end"
    end
end

return Tile

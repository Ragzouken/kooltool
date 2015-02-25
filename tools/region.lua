local Class = require "hump.class"
local Tool = require "tools.tool"

local bresenham = require "utilities.bresenham"
local colour = require "utilities.colour"

local eraser = love.graphics.newImage("images/icons/eraser.png")

local Region = Class {
    __includes = Tool,
    name = "tile",
    sound = love.audio.newSource("sounds/marker pen.wav"),
}

function Region:init(editor, project, region)
    Tool.init(self)
    
    self.editor = editor
    self.project = project
    self.region = region
end

function Region:cursor(sx, sy, wx, wy)
    local target = self.editor:target("tile", sx, sy)
    
    if target then
        local handle = target:tile(sx, sy)

        local tileset = target.tilemap.tileset

        local gx, gy = handle:grid_coords(wx, wy)
        local tw, th = unpack(target.project.gridsize)
        local quad = tileset.quads[self.tile]

        love.graphics.setBlendMode("alpha")
        
        love.graphics.setColor(self.region.colour)
        for contained, x, y in self.region:items(target) do
            love.graphics.rectangle("fill", x*tw, y*th, tw, th)
        end

        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*tw, gy*th, tw, th)
    end
end

function Region:mousepressed(button, sx, sy, wx, wy)
    local target = self.editor:target("tile", sx, sy)

    if button == "l" and target then
        local handle = target:tile(sx, sy)

        self:startdrag("draw")
        self.drag.subject = target
        self.drag.handle = handle

        local x, y = self.drag.handle:grid_coords(wx, wy)
        self.drag.erase = self.region:includes(target, x, y)

        return true, "begin"
    end
end

function Region:mousedragged(action, screen, world)
    if action == "draw" then
        local wx, wy, dx, dy = unpack(world)

        local x1, y1 = self.drag.handle:grid_coords(wx-dx, wy-dy)
        local x2, y2 = self.drag.handle:grid_coords(wx, wy)

        local change = false
        local index = self.tile

        for lx, ly in bresenham.line(x1, y1, x2, y2) do
            if self.drag.erase then
                change = change or self.region:exclude(self.drag.subject, lx, ly)
            else
                change = change or self.region:include(self.drag.subject, lx, ly)
            end
        end

        if change then
            self.sound:stop()
            self.sound:play()
        end
    end
end

function Region:mousereleased(button, sx, sy, wx, wy)
    if button == "l" then
        self:enddrag()

        return true, "end"
    end
end

return Region

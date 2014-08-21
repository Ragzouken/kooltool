local Class = require "hump.class"
local Tool = require "tools.tool"

local Brush = require "brush"

local Marker = Class { __includes = Tool, name = "annotate", }

function Marker:init(project)
    Tool.init(self)
    
    self.project = project
end

function Marker:mousepressed(button, sx, sy, wx, wy)
    if button == "l" then
        self:startdrag("draw")

        local object = self.project:objectAt(wx, wy)
        local surface = self.project.layers.surface

        self.drag.subject = object and object.applyBrush and object or surface

        return true, "begin"
    elseif self.drag and button == "r" then 
        self.drag.erase = true

        return true
    end
end

function Marker:mousedragged(action, screen, world)
    if action == "draw" then
        local colour = not self.drag.erase and {255, 255, 255, 255} or nil
        local size = not self.drag.erase and BRUSHSIZE or BRUSHSIZE * 3
        local wx, wy, dx, dy = unpack(world)

        local x1, y1 = math.floor(wx-dx), math.floor(wy-dy)
        local x2, y2 = math.floor(wx), math.floor(wy)

        local brush, ox, oy = Brush.line(x1, y1, x2, y2, size, colour)
        self.project.layers.annotation:applyBrush(ox, oy, brush, lock, clone)
    end
end

function Marker:mousereleased(button, sx, sy, wx, wy)
    if button == "l" or (self.drag and button == "r") then
        self:enddrag()

        return true, "end"
    end
end

return Marker

local Class = require "hump.class"
local Tool = require "tools.tool"
local Brush = require "tools.brush"

local colour = require "utilities.colour"

local Marker = Class {
    __includes = Tool,
    name = "annotate",
}

function Marker:init(editor)
    Tool.init(self)
    
    self.editor = editor
    self.size = 1
end

function Marker:cursor(sx, sy, wx, wy)
    local target, x, y = self.editor:target("mark", sx, sy)

    if target then
        local bo = math.floor(self.size / 2)
        local x, y = math.floor(wx) - bo, math.floor(wy) - bo

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("fill", x, y, self.size, self.size)

        return love.mouse.getSystemCursor("crosshair")
    end

    return love.mouse.getSystemCursor("no")
end

function Marker:mousepressed(button, sx, sy, wx, wy)
    local target, x, y = self.editor:target("mark", sx, sy)

    if button == "l" and target then
        self:startdrag("draw")
        self.drag.subject = target

        return true, "begin"
    end
end

function Marker:mousedragged(action, screen, world)
    if action == "draw" then
        local erase = love.keyboard.isDown("x", "e")

        local colour = not erase and {255, 255, 255, 255} or nil
        local size = not erase and self.size or self.size * 3
        
        local wx, wy, dx, dy = unpack(screen)

        local x1, y1 = math.floor(wx-dx), math.floor(wy-dy)
        local x2, y2 = math.floor(wx), math.floor(wy)

        x1, y1 = unpack(self.editor:transform(self.drag.subject, x1, y1))
        x2, y2 = unpack(self.editor:transform(self.drag.subject, x2, y2))

        local brush, ox, oy = Brush.line(x1, y1, x2, y2, size, colour)
        self.drag.subject:applyBrush(ox, oy, brush)
    end
end

function Marker:mousereleased(button, sx, sy, wx, wy)
    if button == "l" or (self.drag and button == "r") then
        self:enddrag()

        return true, "end"
    end
end

local digits = {}

for i=1,9 do
    digits[tostring(i)] = i
end

function Marker:keypressed(key, isrepeat, sx, sy, wx, wy)
    if not isrepeat and digits[key] then
        self.size = digits[key]

        return true
    end
end

return Marker

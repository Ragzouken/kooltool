local Class = require "hump.class"
local Tool = require "tools.tool"
local Brush = require "tools.brush"

local colour = require "utilities.colour"

local Draw = Class {
    __includes = Tool,
    name = "draw",
}

function Draw:init(editor, colour)
    Tool.init(self)

    self.editor = editor
    self.colour = colour
    self.size = 1
    self.state = {}
end

function Draw:cursor(sx, sy, wx, wy)
    if self.state.lock then
        local gx, gy = unpack(self.state.lock)

        local tw, th = unpack(self.editor.project.layers.surface.tileset.dimensions)

        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*tw-0.5, gy*th-0.5, tw+1, th+1)
    else
        local target = self.editor:target("draw", sx, sy)

        if self.drag and self.drag.subject and self.drag.subject.entity then
            self.drag.subject.entity:border()
        elseif target then
            if target.entity then target.entity:border() end
        end
    end

    local bo = math.floor(self.size / 2)
    local x, y = math.floor(wx) - bo, math.floor(wy) - bo

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(self.colour)
    love.graphics.rectangle("fill", x, y, self.size, self.size)
end

function Draw:mousepressed(button, sx, sy)
    if button == "l" then
        local target, x, y = self.editor:target("draw", sx, sy)

        if love.keyboard.isDown("lalt") then
            self.colour = target:sample(x, y)

            return true
        else
            self:startdrag("draw")

            self.drag.subject = target

            return true, "begin"
        end
    elseif self.drag and button == "r" then 
        self.drag.erase = true

        return true
    end
end

function Draw:mousedragged(action, screen, world)
    if action == "draw" then
        local colour = not self.drag.erase and self.colour or nil
        local lock

        local wx, wy, dx, dy = unpack(screen)

        local x1, y1 = math.floor(wx-dx), math.floor(wy-dy)
        local x2, y2 = math.floor(wx), math.floor(wy)

        x1, y1 = unpack(self.editor:transform(self.drag.subject, x1, y1))
        x2, y2 = unpack(self.editor:transform(self.drag.subject, x2, y2))

        local brush, ox, oy = Brush.line(x1, y1, x2, y2, self.size, colour)
        self.drag.subject:applyBrush(ox, oy, brush, 
            self.state.lock or self.state.resize, self.state.cloning)
    end
end

function Draw:mousereleased(button, sx, sy, wx, wy)
    if button == "l" or (self.drag and button == "r") then
        self:enddrag()
        self.state.cloning = self.state.cloning and {} or nil

        return true, "end"
    end
end

local digits = {}

for i=1,9 do
    digits[tostring(i)] = i
end

function Draw:keypressed(key, isrepeat, sx, sy, wx, wy)
    if isrepeat then return end

    if key == "lctrl" then
        self.state.cloning = {}

        return true
    elseif key == "lshift" then
        local target = self.editor:target("draw", sx, sy)

        if target and target.entity then
            self.state.resize = target

            return true
        end

        self.state.lock = {self.editor.project.layers.surface.tilemap:gridCoords(wx, wy)}
    
        return true
    elseif digits[key] then
        self.size = digits[key]

        return true
    elseif key == " " then
        self.colour = {colour.random(0, 255)}

        return true
    end
end

function Draw:keyreleased(key, sx, sy, wx, wy)
    if key == "lctrl" then
        self.state.cloning = nil

        return true
    elseif key == "lshift" then
        self.state.lock = nil
        self.state.resize = nil

        return true
    end
end

return Draw

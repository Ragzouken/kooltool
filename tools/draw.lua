local Class = require "hump.class"
local Tool = require "tools.tool"
local Brush = require "tools.brush"

local colour = require "utilities.colour"

local Draw = Class {
    __includes = Tool,
    name = "draw",
}

function Draw:init(project, colour)
    Tool.init(self)

    self.project = project
    self.colour = colour
    self.size = 1
    self.state = {}
end

function Draw:cursor(sx, sy, wx, wy)
    if self.state.lock then
        local gx, gy = unpack(self.state.lock)

        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*32-0.5, gy*32-0.5, 32+1, 32+1)
    else
        local object = self.project:objectAt(wx, wy)

        if self.drag and self.drag.subject and self.drag.subject.sprite then
            self.drag.subject:border()
        elseif object then
            if object.applyBrush then 
                object:border()
            else
                return
            end
        end
    end

    local bo = math.floor(self.size / 2)
    local x, y = math.floor(wx) - bo, math.floor(wy) - bo

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(self.colour)
    love.graphics.rectangle("fill", x, y, self.size, self.size)
end

function Draw:mousepressed(button, sx, sy, wx, wy)
    if button == "l" then
        local surface = self.project.layers.surface
        local object = self.project:objectAt(wx, wy)

        if object and not object.applyBrush then
            return false
        end

        if love.keyboard.isDown("lalt") then
            self.colour = surface:sample(wx, wy)

            return true
        else
            self:startdrag("draw")

            local object = self.project:objectAt(wx, wy)
            local object = object and object.applyBrush and object

            self.drag.sprite = object
            self.drag.subject = object or surface

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

        local wx, wy, dx, dy = unpack(world)

        local x1, y1 = math.floor(wx-dx), math.floor(wy-dy)
        local x2, y2 = math.floor(wx), math.floor(wy)

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
        if self.project:objectAt(wx, wy) then
            self.state.resize = true

            return true
        end

        self.state.lock = {self.project.layers.surface.tilemap:gridCoords(wx, wy)}
    
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

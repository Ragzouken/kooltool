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
    local draw, entity

    if self.drag and self.drag.subject and self.drag.subject.border then
        entity = self.drag.subject
    elseif self.state.lock then
        if self.state.lock.border then
            entity = self.state.lock
        else
            local gx, gy = unpack(self.state.lock)
            local tw, th = unpack(self.editor.project.layers.surface.tileset.dimensions)

            draw = true

            local target, x, y = self.editor:target("draw", sx, sy)
            if target.tilemap then
                local tx, ty = target.tilemap:gridCoords(x, y)
                if tx ~= gx or ty ~= gy then
                    draw = false
                end
            end

            love.graphics.setColor(colour.cursor(0))
            love.graphics.rectangle("line", gx*tw-0.5, gy*th-0.5, tw+1, th+1)
        end
    else
        local target = self.editor:target("draw", sx, sy)

        draw = target

        if target and target.border then
            target:border()
        end
    end

    if entity then
        local x, y = unpack(self.editor:transform(entity.parent, sx, sy))

        draw = entity.shape:contains(x, y)
       
        entity:border()
    end

    if draw then
        local bo = math.floor(self.size / 2)
        local x, y = math.floor(wx) - bo, math.floor(wy) - bo

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(self.colour)
        love.graphics.rectangle("fill", x, y, self.size, self.size)

        return love.mouse.getSystemCursor("crosshair")
    end

    return love.mouse.getSystemCursor("no")
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
    end
end

function Draw:mousedragged(action, screen, world)
    if action == "draw" then
        local colour = not love.keyboard.isDown("x", "e") and self.colour or nil
        local lock

        local wx, wy, dx, dy = unpack(screen)

        local x1, y1 = math.floor(wx-dx), math.floor(wy-dy)
        local x2, y2 = math.floor(wx), math.floor(wy)

        x1, y1 = unpack(self.editor:transform(self.drag.subject, x1, y1))
        x2, y2 = unpack(self.editor:transform(self.drag.subject, x2, y2))

        local brush, ox, oy = Brush.line(x1, y1, x2, y2, self.size, colour)
        self.drag.subject:applyBrush(ox, oy, brush, self.state.lock, self.state.cloning)
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

    if key == "lctrl" or key == "rctrl" then
        self.state.cloning = {}

        return true
    elseif key == "lshift" or key == "rshift" then
        local target = self.editor:target("draw", sx, sy)

        if target then
            if target.sprite then
                self.state.lock = target
            else
                self.state.lock = {target.tilemap:gridCoords(wx, wy)}
            end

            return true
        end

        return false
    elseif digits[key] then
        self.size = digits[key]

        return true
    elseif key == " " then
        self.colour = {colour.random(0, 255)}

        return true
    end
end

function Draw:keyreleased(key, sx, sy, wx, wy)
    if key == "lctrl" or key == "rctrl" then
        self.state.cloning = nil

        return true
    elseif key == "lshift" or key == "rshift" then
        self.state.lock = nil
        self.state.resize = nil

        return true
    end
end

return Draw

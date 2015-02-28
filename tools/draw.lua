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

    if self.drag and self.drag.subject and self.drag.subject.type == "Entity" then
        entity = self.drag.subject
    elseif self.state.lock then
        if self.state.lock.type == "Entity" then
            entity = self.state.lock
        else
            local gx, gy = unpack(self.state.lock)
            local tw, th = unpack(self.editor.project.gridsize)

            draw = true

            local target, x, y = self.editor:target("draw", sx, sy)
            if target.tilemap then
                local tx, ty = target.tilemap.tiledata:grid_coords(x, y)
                if tx ~= gx or ty ~= gy then
                    draw = false
                end
            end

            love.graphics.setColor(colour.cursor(0))
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", gx*tw-1.5, gy*th-1.5, tw+3, th+3)
        end
    else
        local target = self.editor:target("draw", sx, sy)

        draw = target

        if target then target.border = true end
    end

    if entity then
        local x, y = unpack(self.editor:transform(entity, sx, sy))

        draw = entity.shape:contains(x, y)

        entity.border = true
    end

    if draw then
        local bo = math.floor(self.size / 2)
        local x, y = math.floor(wx) - bo, math.floor(wy) - bo

        love.graphics.setLineWidth(0.25)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(self.colour or {colour.cursor(0)})
        love.graphics.rectangle(self.colour and "fill" or "line", x, y, self.size, self.size)

        return love.mouse.getSystemCursor("crosshair")
    end

    return love.mouse.getSystemCursor("no")
end

function Draw:mousepressed(button, sx, sy)
    local target, x, y = self.editor:target("draw", sx, sy)

    if button == "l" and target then
        local handle = target:pixel(x, y)

        if love.keyboard.isDown("lalt") then
            self.colour = handle:sample(x, y)

            return true
        else
            self:startdrag("draw")

            self.drag.subject = target
            self.drag.handle = handle

            return true, "begin"
        end
    end
end

function Draw:mousedragged(action, screen, world)
    if action == "draw" then
        local colour = self.colour
        local lock

        local wx, wy, dx, dy = unpack(screen)

        local x1, y1 = math.floor(wx-dx), math.floor(wy-dy)
        local x2, y2 = math.floor(wx), math.floor(wy)

        x1, y1 = unpack(self.editor:transform(self.drag.subject, x1, y1))
        x2, y2 = unpack(self.editor:transform(self.drag.subject, x2, y2))

        local brush, ox, oy = Brush.line(x1, y1, x2, y2, self.size, colour)
        self.drag.handle.options = {lock=self.state.lock, cloning=self.state.cloning}
        self.drag.handle:brush(brush, ox, oy)
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
                self.state.lock = {target.tilemap.tiledata:grid_coords(wx, wy)}
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

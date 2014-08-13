local Class = require "hump.class"
local shapes = require "collider.shapes"
local colour = require "colour"

local Notebox = Class {
    font = love.graphics.newFont("fonts/PressStart2P.ttf", 8)
}

Notebox.font:setFilter("linear", "nearest")

function string:split(pat)
    local fields = {}
    local start = 1
    self:gsub("()("..pat..")", function(c,d)
        table.insert(fields,self:sub(start,c-1))
        start = c + #d
    end)
    table.insert(fields, self:sub(start))
    return fields
end

function Notebox:deserialise(data)
    self.x, self.y, self.text = unpack(data)
end

function Notebox:serialise()
    return {self.x, self.y, self.text}
end

function Notebox:init(layer, x, y, text)
    self.layer = layer
    self.x, self.y = x, y
    
    self.text = text or ""

    self:refresh()
end

function Notebox:draw(editing)
    love.graphics.setFont(self.font)

    local lines, width = self.memo.lines, self.memo.width

    local font_height = self.font:getHeight()
    local height = font_height * #lines
    local oy = self.font:getAscent() - self.font:getBaseline()

    local x, y = self.x - math.ceil(width / 4), self.y - math.ceil(height / 4)

    love.graphics.push()
    love.graphics.scale(0.5)

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", x*2-1, y*2, width+2, height+2)

    love.graphics.setColor(255, 255, 255, 255)
    for i, line in ipairs(lines) do
        love.graphics.printf(line, x*2, y*2 + oy + (i - 1) * font_height, self.memo.width)
    end

    if editing then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.printf(lines[#lines]:gsub(".", "_") .. "*", x*2, y*2 + oy + (#lines - 1) * font_height, self.memo.width)
    end
    love.graphics.pop()
end

function Notebox:move(dx, dy)
    self.shape:move(dx, dy)
    self.x, self.y = self.x + dx, self.y + dy
end

function Notebox:moveTo(x, y)
    self.shape:moveTo(x, y)
    self.x, self.y = x, y
end

function Notebox:refresh()
    local lines = {}
    local width = 0

    for i, line in ipairs(self.text:split("\n")) do
        lines[#lines+1] = line
        width = math.max(width, self.font:getWidth(line))
    end

    self.memo = {lines = lines, width = width}

    local height = self.font:getHeight() * #lines
    local oy = self.font:getAscent() - self.font:getBaseline()

    local x, y = self.x - math.ceil(width*2), self.y - math.ceil(height*2)

    local x1, y1 = 0, 0
    local x2, y2 = width/2+3, height/2+3

    local shape = shapes.newPolygonShape(x1, y1, x2, y1, x2, y2, x1, y2)
    shape:moveTo(self.x, self.y)
    shape.notebox = self
    if self.shape then self.layer:swapShapes(self.shape, shape) end
    self.shape = shape
end

function Notebox:keypressed(key)
    if key == "backspace" then self.text = string.sub(self.text, 1, #self.text-1) end
    if key == "return" then self.text = self.text .. "\n" end
    
    self:refresh()

    if key == "backspace" or key == "return" then
        return true
    end

    return key ~= "escape" and not love.keyboard.isDown("lctrl")
end

function Notebox:textinput(character)
    self.text = self.text .. character
    self:refresh()

    return true
end

return Notebox

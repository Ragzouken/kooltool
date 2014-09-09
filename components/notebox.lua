local Class = require "hump.class"
local shapes = require "collider.shapes"
local colour = require "utilities.colour"

local Notebox = Class {
    font = love.graphics.newFont("fonts/PressStart2P.ttf", 8),
    typing_sound = love.audio.newSource("sounds/typing.wav"),
    
    padding = 4,
    spacing = 4,
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
    local height = (font_height+self.spacing) * #lines
    local oy = self.font:getAscent() - self.font:getBaseline() + self.spacing/2

    local x, y = self.x - width / 4, self.y - height / 4

    love.graphics.push()
    love.graphics.scale(0.5)

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", x*2-self.padding, y*2-self.padding, 
                                    width+2*self.padding, height+2*self.padding)

    love.graphics.setColor(255, 255, 255, 255)
    for i, line in ipairs(lines) do
        love.graphics.printf(line, x*2, y*2 + oy + (i - 1) * (font_height+self.spacing), self.memo.width)
    end

    if editing then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.printf(lines[#lines]:gsub(".", "_") .. "*", x*2, y*2 + oy + (#lines - 1) * (font_height+self.spacing), self.memo.width)
    end
    love.graphics.pop()

    if editing then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.setLineWidth(0.5)
        self.shape:draw()
        love.graphics.setLineWidth(1)
    end
end

function Notebox:move(dx, dy)
    self.shape:move(dx, dy)
    self.x, self.y = self.x + dx, self.y + dy
end

function Notebox:moveTo(x, y)
    x, y = math.floor(x * 2) / 2, math.floor(y * 2) / 2

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

    local height = (self.font:getHeight() + self.spacing) * #lines
    local oy = self.font:getAscent() - self.font:getBaseline()

    local x1, y1 = 0, 0
    local x2, y2 = (width)/2+self.padding, (height)/2+self.padding

    local shape = shapes.newPolygonShape(x1, y1, x2, y1, x2, y2, x1, y2)
    shape:moveTo(self.x, self.y)
    shape.notebox = self
    if self.shape then self.layer:swapShapes(self.shape, shape) end
    self.shape = shape
end

function Notebox:type(string)
    self.text = self.text .. string

    self.typing_sound:stop()
    self.typing_sound:play()

    self:refresh()
end

function Notebox:keypressed(key)
    if key == "backspace" then
        self.text = string.sub(self.text, 1, #self.text-1)
        self:type("")
        
        return true
    elseif key == "return" then
        self:type("\n")

        return true
    end

    return key ~= "escape" and not love.keyboard.isDown("lctrl")
end

function Notebox:textinput(character)
    self:type(character)

    return true
end

return Notebox
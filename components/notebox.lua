local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"

local Notebox = Class {
    __includes = Panel,
    name = "Generic Notebox",

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
    local x, y, text = unpack(data)
    self.text = text
    self:refresh()
    self:move_to { x = x, y = y, anchor = {0.5, 0.5} }
end

function Notebox:serialise()
    local x, y = self.shape:coords { anchor = {0.5, 0.5} }

    return {x, y, self.text}
end

function Notebox:init(layer)
    Panel.init(self, { actions = {"drag"},
                       shape = shapes.Rectangle { x = 0, y = 0, w = 0, h = 0 } })

    self.layer = layer
    
    self.text = "[INVALID NOTE]"

    self:refresh()
end

function Notebox:blank(x, y, text)
    self.text = text
    self:refresh()
    self:move_to { x = x, y = y, anchor = {0.5, 0.5} }
end

function Notebox:draw(editing)
    love.graphics.setFont(self.font)

    local lines, width = self.memo.lines, self.memo.width

    local font_height = self.font:getHeight()
    local height = (font_height+self.spacing) * #lines
    local oy = self.font:getAscent() - self.font:getBaseline() + self.spacing/2

    local x,  y  = self.shape.x * 2, self.shape.y * 2
    local tx, ty = x + self.padding, y + self.padding

    love.graphics.push()
    love.graphics.scale(0.5)

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", x+0.5, y+0.5, 
                                    width+2*self.padding-1, height+2*self.padding-1)

    love.graphics.setColor(255, 255, 255, 255)
    for i, line in ipairs(lines) do
        love.graphics.printf(line,
                             tx, ty + oy + (i - 1) * (font_height+self.spacing),
                             self.memo.width)
    end

    if editing then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.printf(lines[#lines]:gsub(".", "_") .. "*",
                             tx, ty + oy + (#lines - 1) * (font_height+self.spacing),
                             self.memo.width)
    end
    love.graphics.pop()

    if editing then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.setLineWidth(0.5)
        self.shape:draw("line")
        love.graphics.setLineWidth(1)
    end

    self:draw_children()
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

    local x, y = self.shape.x, self.shape.y
    local w, h = width+self.padding*2, height+self.padding*2

    self.shape:init { x = x,     y = y,
                      w = w / 2, h = h / 2 }

    self.shape.notebox = self
    self.name = "notebox \"" .. self.text .. "\""
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

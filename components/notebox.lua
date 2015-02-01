local Class = require "hump.class"
local Text = require "interface.elements.text"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local wrap = require "utilities.wrap"
local parse = require "engine.parse"

local Notebox = Class {
    __includes = Text,
    type = "Notebox",
    name = "Generic Notebox",
    actions = {"drag", "type", "remove", "block", "tooltip"},
    tooltip = "note",

    font = Text.fonts.small,

    padding = 4,
    spacing = 4,

    text = "[INVALID NOTE]",
    multiline = true,
}

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

function Notebox:deserialise(resources, data)
    local x, y, text = unpack(data)
    self.text = text
    self:refresh()
    self:move_to { x = x, y = y }
end

function Notebox:serialise(resources)
    return {self.x, self.y, self.text}
end

function Notebox:init(layer)
    Text.init(self, { shape = shapes.Rectangle { anchor = {0.5, 0.5} } })
    
    self.layer = layer
    self.unset = false

    self:refresh()
end

function Notebox:blank(x, y, text)
    self.text = text
    self.unset = true
    self:refresh()
    self:move_to { x = x, y = y, anchor = {0.5, 0.5} }
end

function Notebox:draw(params)
    if MODE ~= EDITOR and string.match(self.text, "%[(.+)%]") then return end 

    love.graphics.setFont(self.font)

    local lines, width = self.memo.lines, self.memo.width
    local cursor_lines = wrap.cursor(self.text, self.cursor)

    local font_height = self.font:getHeight()
    local height = (font_height+self.spacing) * #lines
    local oy = self.font:getAscent() - self.font:getBaseline() + self.spacing/2

    local x,  y  = self.shape.x * 2, self.shape.y * 2
    local tx, ty = x + self.padding, y + self.padding

    love.graphics.push()
    love.graphics.scale(0.5)

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", x+0.5, y+0.5, 
                                    width+2*self.padding-1, height+2*self.padding-1)

    for i, line in ipairs(lines) do
        local dx, dy = tx, ty + oy + (i - 1) * (font_height+self.spacing)

        love.graphics.setColor(self.colours.text)
        love.graphics.print(line, dx, dy)

        if self.focused then
            love.graphics.setColor(colour.cursor(0, 255))
            love.graphics.print(cursor_lines[i], dx, dy)
        end
    end

    love.graphics.pop()

    if EDITOR.focus == self then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.setLineWidth(0.5)
        self.shape:draw("line")
        love.graphics.setLineWidth(1)
    end
end

function Notebox:refresh()
    local lines = {}
    local width = 0

    for i, line in ipairs(self.text:split("\n")) do
        lines[#lines+1] = line
        width = math.max(width, self.font:getWidth(line))
    end

    self._wrapped = self.text
    self._lines = lines

    self.memo = {lines = lines, width = width}

    local height = (self.font:getHeight() + self.spacing) * #lines
    local oy = self.font:getAscent() - self.font:getBaseline()

    local w, h = width+self.padding*2, height+self.padding*2

    local dw, dh = w/2 - self.shape.w, h/2 - self.shape.h

    self.shape:grow { right = dw, down = dh }
    self.shape:move_to { x = 0, y = 0, anchor = {0.5, 0.5} }

    self.shape.notebox = self
    self.name = "notebox \"" .. self.text .. "\""

    local _, error = parse.test(self.text)
    self.tooltip = error
end

function Notebox:defocus()
    Text.defocus(self)

    if self.text == "" then
        self.unset = true
        self.text = "[note]"
        self:refresh()
    end
end

function Notebox:typed(string)
    if self.unset then
        self.unset = false
        self.text = ""
        self.cursor = 0
    end

    Text.typed(self, string)

    self:refresh()
end

function Notebox:remove()
    self.layer:remove(self)
end

return Notebox

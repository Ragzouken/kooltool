local Class = require "hump.class"
local Event = require "utilities.event"
local Panel = require "interface.elements.panel"

local colour = require "utilities.colour"
local wrap = require "utilities.wrap"

local Text = Class {
    __includes = Panel,
    name = "Generic Textbox",
    actions = {"type"},

    fonts = {
        large = love.graphics.newFont("fonts/PressStart2P.ttf", 32),
        medium = love.graphics.newFont("fonts/PressStart2P.ttf", 16),
        small = love.graphics.newFont("fonts/PressStart2P.ttf", 8),
    },

    typing_sound = love.audio.newSource("sounds/typing.wav"),

    colours = {
        stroke = {  0,   0,   0, 255}, 
        fill   = {  0,   0,   0, 255},
        text   = {255, 255, 255, 255},
    },

    padding = 4,
    spacing = 2,

    multiline = false,
}

for name, font in pairs(Text.fonts) do
    font:setFilter("linear", "nearest")
end

function Text:init(params)
    Panel.init(self, params)

    self.colours.text = (params.colours and params.colours.text) or self.colours.text
    self.text = params.text
    self.font = params.font or self.fonts.small
    
    self.padding = params.padding or self.padding
    self.spacing = params.spacing or self.spacing
    self.multiline = params.multiline or self.multiline

    self.focused = false
    self.cursor = 1

    self.changed = Event()

    self:refresh()
end

function Text:draw()    
    Panel.draw(self)
    
    love.graphics.setBlendMode("alpha")

    local height = self.font:getHeight() + self.spacing
    local oy = self.font:getAscent() - self.font:getBaseline()
    love.graphics.setFont(self.font)

    love.graphics.push()
    love.graphics.translate(self.shape.x, self.shape.y)
    
    local text, lines = self._wrapped, self._lines
    local cursor_lines = wrap.cursor(lines, self.cursor)

    for i, line in ipairs(lines) do
        local dx, dy = self.padding, self.padding + oy + height * (i - 1)

        love.graphics.setColor(self.colours.text)
        love.graphics.print(line, dx, dy)
        
        if self.focused then
            love.graphics.setColor(colour.cursor(0, 255))
            love.graphics.print(cursor_lines[i], dx, dy)
        end
    end

    love.graphics.pop()
end

function Text:focus()
    self.focused = true
    self.cursor = #self.text:gsub("\n", "")
end

function Text:defocus()
    self.focused = false
end

function Text:type(string)
    local i = self.cursor
    self.text = string.format("%s%s%s",
                              self.text:sub(1,i),
                              string,
                              self.text:sub(i+1))

    self.typing_sound:stop()
    self.typing_sound:play()

    self.cursor = self.cursor + #string:gsub("\n", "")

    self:refresh()

    self.changed:fire(self.text)
end

function Text:refresh()
    self._wrapped, self._lines = wrap.wrap(self.font,
                                           self.text,
                                           self.shape.w - self.padding * 2)
end

function Text:keypressed(key)
    if key == "backspace" then
        if self.cursor > 0 then
            self.text = string.format("%s%s",
                                      self.text:sub(1,self.cursor-1),
                                      self.text:sub(self.cursor+1))
            self.cursor = math.max(0, self.cursor - 1)
        end

        self:type("")
        
        return true
    elseif key == "delete" then
        self.text = string.format("%s%s",
                                  self.text:sub(1,self.cursor),
                                  self.text:sub(self.cursor+2))
        self:type("")
        
        return true
    elseif key == "return" then
        if self.multiline and love.keyboard.isDown("lshift", "rshift") then
            self:type("\n")
        else
            EDITOR.focus = nil
        end

        return true
    elseif key == "left" then
        self.cursor = math.max(0, self.cursor - 1)

        self:type("")
    elseif key == "right" then
        self.cursor = math.min(#self.text, self.cursor + 1)

        self:type("")
    elseif key == "v" and love.keyboard.isDown("lctrl", "rctrl") then
        self:type(love.system.getClipboardText())
    end

    return key ~= "escape" and not love.keyboard.isDown("lctrl", "rctrl")
end

return Text


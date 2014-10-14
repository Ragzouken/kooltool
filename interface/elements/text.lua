local Class = require "hump.class"
local Event = require "utilities.event"
local Panel = require "interface.elements.panel"

local colour = require "utilities.colour"

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

    self.changed = Event()
end

function Text:draw()    
    Panel.draw(self)
    
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(self.colours.text)
    
    if EDITOR.focus == self then
        love.graphics.setColor(colour.cursor(0))
    end

    local height = self.font:getHeight()
    local oy = self.font:getAscent() - self.font:getBaseline()
    love.graphics.setFont(self.font)

    love.graphics.push()
    love.graphics.translate(self.shape.x, self.shape.y)
    
    love.graphics.printf(self.text, self.padding, self.padding + oy, self.shape.w)

    love.graphics.pop()
end

function Text:type(string)
    self.text = self.text .. string

    self.typing_sound:stop()
    self.typing_sound:play()

    --self:refresh()

    self.changed:fire(self.text)
end

function Text:keypressed(key)
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

return Text


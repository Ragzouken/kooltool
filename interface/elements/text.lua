local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Text = Class {
    __includes = Panel,

    fonts = {
        large = love.graphics.newFont("fonts/PressStart2P.ttf", 32),
        medium = love.graphics.newFont("fonts/PressStart2P.ttf", 16),
        small = love.graphics.newFont("fonts/PressStart2P.ttf", 8),
    },
}

function Text:init(params)
    Panel.init(self, params)
    
    self.colours.text = self.colours.text or self.colours.stroke
    self.text = params.text
    self.font = params.font or self.fonts.small
    
    self.padding = 8
end

function Text:draw()    
    Panel.draw(self)
    
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(self.colours.text)
    
    local height = self.font:getHeight()
    local oy = self.font:getAscent() - self.font:getBaseline()
    love.graphics.setFont(self.font)

    love.graphics.push()
    love.graphics.translate(self.shape:anchor())
    
    love.graphics.printf(self.text, self.padding, self.padding + oy, self.shape.w)
    
    love.graphics.pop()
end

return Text


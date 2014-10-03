local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Box = Class { __includes = Panel }

function Box:init(depth, x, y, width, height)
    Panel.init(self, depth)
    
    self.x, self.y = x, y
    self.width, self.height = width, height 
end

function Box:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 0, 255, 64)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(255, 0, 255, 255)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

return Box

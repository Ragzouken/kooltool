local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Layer = Class {
    __includes = Panel,
    name = "Generic Project Layer",
}

function Layer:init(project)
    Panel.init(self)

    self.project = project
end

function Layer:draw(params)
    Panel.draw(self, params)

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 32)
    love.graphics.circle("fill", 0, 0, 16, 32)
end

function Layer:objectAt(x, y)
end

return Layer

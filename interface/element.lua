local Class = require "hump.class"

local Element = Class {}

function Element:init()
    self.children = {}
end

function Element:addChild(pane)
    self.children[pane] = true
end

function Element:removeChild(pane)
    self.children[pane] = nil
end

function Element:update(dt)
end

function Element:draw()
end

function Element:mousepressed()
end

function Element:mousereleased()
end

function Element:keypressed()
end

function Element:keyreleased()
end

function Element:textinput()
end

return Element

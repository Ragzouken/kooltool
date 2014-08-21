local Class = require "hump.class"

local Pane = Class {}

function Pane:init(interface)
    self.interface = interface
end

function Pane:update(dt)
end

function Pane:draw()
end

function Pane:mousepressed()
end

function Pane:mousereleased()
end

function Pane:keypressed()
end

function Pane:keyreleased()
end

function Pane:textinput()
end

return Pane

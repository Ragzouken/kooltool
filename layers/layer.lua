local Class = require "hump.class"

local Layer = Class {}

function Layer:init(project)
    self.project = project
end

function Layer:update(dt)
end

function Layer:draw()
end

function Layer:objectAt(x, y)
end

return Layer

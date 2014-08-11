local Class = require "hump.class"

local Layer = Class {}

function Layer:init(project)
    self.project = project
end

function Layer:draw()
end

return Layer

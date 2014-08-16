local Class = require "hump.class"

local Mouse = Class {}

function Mouse:init(project)
    self.project = project
end

function Mouse:mousepressed(x, y, button)
    local element = self.project:objectAt(x, y, filters)

    self.drag = {x, y, element}
end

function Mouse:mousereleased(x, y, button)
end

return Mouse

local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Layer = Class { __includes = Panel }

function Layer:init(project)
    Panel.init(self)

    self.project = project
end

function Layer:update(dt)
end

function Layer:objectAt(x, y)
end

return Layer

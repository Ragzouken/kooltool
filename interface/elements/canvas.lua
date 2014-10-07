local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Canvas = Class {
    __includes = Panel,
    actions = { "draw" },
}

function Canvas:init(params)
    Panel.init(self, params)
end

return Canvas

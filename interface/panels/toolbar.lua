local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"

local Radio = require "interface.elements.radio"

local Toolbar = Class {
    __includes = Panel,
    name = "kooltool toolbar",
}

function Toolbar:init(params)
    local w, h = unpack(params.size)
    local height = (h + 1) * #params.buttons - 1
    
    params.shape = shapes.Rectangle { x = params.x, y = params.y,
                                      w = w+2,      h = height,
                                      anchor = params.anchor }
    
    Panel.init(self, params)
    
    local group = Radio.Group()
    
    for i, button in ipairs(params.buttons) do
        local x, y = 1, (h + 1) * (i - 1) + 1
        local button = Radio { x = x, y = y,
                               icon = button[1],
                               action = button[2],
                               group = group }
        
        self:add(button)
    end
end

return Toolbar

local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"

local Radio = require "interface.elements.radio"

local Toolbar = Class { __includes = Panel, }

function Toolbar:init(params)
    local height = (32 + 1) * #params.buttons - 1
    
    params.shape = shapes.Rectangle(params.x, params.y,
                                    34, height,
                                    params.anchor)
    
    Panel.init(self, params)
    
    local group = Radio.Group()
    
    for i, button in ipairs(params.buttons) do
        local x, y = 1, (32 + 1) * (i - 1) + 1
        local button = Radio{x=x, y=y, icon=button[1], action=button[2], group=group}
        
        self:add(button)
    end
end

return Toolbar

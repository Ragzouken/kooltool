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
    local height = (h + 1) * (math.min(#params.buttons, 16))
    
    local cols = math.floor((#params.buttons - 1) / 16) + 1
    local width = cols * w

    params.shape = shapes.Rectangle { x = params.x, y = params.y,
                                      w = width+2,  h = height+2,
                                      anchor = params.anchor }
    
    Panel.init(self, params)
    
    local group = Radio.Group()

    for i, button in ipairs(params.buttons) do
        local col = math.floor((i - 1) / 16)
        local row = (i - 1) % 16

        local x, y = 32 * col, (h + 1) * row + 1
        local tooltip = button[3]
        local button = Radio { x = x, y = y,
                               icon = button[1],
                               action = button[2],
                               group = group,
                               actions = {"press", button[3] and "tooltip"}, }

        button.tooltip = tooltip

        self:add(button)
    end
end

return Toolbar

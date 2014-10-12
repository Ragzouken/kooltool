local Class = require "hump.class"
local elements = require "interface.elements"

local ProjectPanel = Class {
    __includes = elements.Panel,
    name = "kooltool project panel",
}

function ProjectPanel:init(project, params)
    elements.Panel.init(self, {
        shape = elements.shapes.Rectangle {x = params.x,   y = params.y,
                                           w = 448, h = 64, 
                                           anchor = params.anchor},
    })

    local icon = elements.Button{
        x = 0, y = 0, w = 64, h = 64,
        icon = {image = project.icon, quad = love.graphics.newQuad(0, 0, 64, 64, 64, 64)},
    }

    local title = elements.Text{
        shape = elements.shapes.Rectangle { x = 64,  y = 0,
                                            w = 384, h = 32 - 4,
                                            anchor = {0, 0}},
        colours = {
            stroke = PALETTE.colours[1],
            fill = PALETTE.colours[1],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = project.name,
    }
    
    local description = elements.Text{
        shape = elements.shapes.Rectangle { x = 64,  y = 32 - 4,
                                            w = 384, h = 32 + 4,
                                            anchor = {0, 0}},
        colours = {
            stroke = PALETTE.colours[2],
            fill = PALETTE.colours[2],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.small,
        text = project.description,
    }

    title.changed:add(function(text) project.name = text end)
    description.changed:add(function(text) project.description = text end)

    self:add(icon)
    self:add(title)
    self:add(description)
end

return ProjectPanel

local Class = require "hump.class"
local elements = require "interface.elements"

local generators = require "generators"

local NewProjectPanel = Class {
    __includes = elements.Panel,
    name = "kooltool new project panel",
}

function NewProjectPanel:init(project, params, new)
    elements.Panel.init(self, {
        shape = elements.shapes.Rectangle {x = params.x,   y = params.y,
                                           w = 448, h = 64, 
                                           anchor = params.anchor},
    })

    local title = elements.Text{
        shape = elements.shapes.Rectangle { x =  64, y = 0,
                                            w = 384, h = 32 - 4,
                                            anchor = {0, 0}},
        colours = {
            stroke = PALETTE.colours[1],
            fill = PALETTE.colours[1],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = project.name,

        actions = {},
    }
    
    local description = elements.Text{
        shape = elements.shapes.Rectangle { x =  64, y = 32 - 4,
                                            w = 384, h = 32 + 4,
                                            anchor = {0, 0}},
        colours = {
            stroke = PALETTE.colours[2],
            fill = PALETTE.colours[2],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = "tile size:",

        actions = {},
    }

    local size = elements.Panel {
        shape = elements.shapes.Rectangle { x = 192, y =   6,
                                            w =   0, h =   0,
                                            anchor = {0, 0} },
    }

    local width = elements.Text{
        shape = elements.shapes.Rectangle { x =  0,  y =  0, 
                                            w = 40,  h = 24,
                                            anchor = {0, 0}},
        colours = {
            stroke = {255, 255, 255, 255},
            fill   = {  0,   0,   0, 255},
            text   = {255, 255, 255, 255},
        },

        font = elements.Text.fonts.medium,
        text = "32",
    }

    local height = elements.Text{
        shape = elements.shapes.Rectangle { x = 48,  y =  0, 
                                            w = 40,  h = 24,
                                            anchor = {0, 0}},
        colours = {
            stroke = {255, 255, 255, 255},
            fill   = {  0,   0,   0, 255},
            text   = {255, 255, 255, 255},
        },

        font = elements.Text.fonts.medium,
        text = "32",
    }

    local function create()
        local w, h = tonumber(width.text) or 32, tonumber(height.text) or 32
        local project = generators.project.default{w, h}
        
        new(project)
    end 

    local icon = elements.Button{
        x = 0, y = 0, w = 64, h = 64,
        icon = {image = project.icon, quad = love.graphics.newQuad(0, 0, 64, 64, 64, 64)},
        action = create,
    }

    local button = elements.Text {
        shape = elements.shapes.Rectangle { x = 96,  y =  0, 
                                            w = 92,  h = 24,
                                            anchor = {0, 0}},
        colours = {
            stroke = PALETTE.colours[1],
            fill = PALETTE.colours[1],
            text = {255, 255, 255, 255},
        },

        font = elements.Text.fonts.medium,
        text = " GO!",
        actions = {"press"},
    }

    button.event = create

    self:add(icon)
    self:add(title)
    self:add(description)

    description:add(size)

    size:add(width)
    size:add(height)
    size:add(button)
end

return NewProjectPanel

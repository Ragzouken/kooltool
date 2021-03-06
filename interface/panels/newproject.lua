local Class = require "hump.class"
local elements = require "interface.elements"

local generators = require "generators"

local NewProjectPanel = Class {
    __includes = elements.Panel,
    name = "kooltool new project panel",
    colours = elements.Panel.COLOURS.black,
}

function NewProjectPanel:init(project, params, new)
    elements.Panel.init(self, {
        x = params.x, y = params.y,
        shape = elements.shapes.Rectangle {w = 448, h = 64, 
                                           anchor = params.anchor},
    })

    local title = elements.Text{
        x = 64, y = 0,

        shape = elements.shapes.Rectangle { w = 384, h = 32 - 4 },
        colours = {
            line = PALETTE.colours[1],
            fill = PALETTE.colours[1],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = project.name,

        actions = {},
    }
    
    local description = elements.Text{
        x = 64, y = 32 - 4,

        shape = elements.shapes.Rectangle { w = 384, h = 32 + 4 },
        colours = {
            line = PALETTE.colours[2],
            fill = PALETTE.colours[2],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = "tile size:",

        actions = {},
    }

    local size = elements.Panel {
        x = 192, y = 6,

        shape = elements.shapes.Rectangle.Null(),
    }

    local width = elements.Text{
        shape = elements.shapes.Rectangle { w = 40,  h = 24 },
        colours = {
            line = {255, 255, 255, 255},
            fill   = {  0,   0,   0, 255},
            text   = {255, 255, 255, 255},
        },

        font = elements.Text.fonts.medium,
        text = "32",
    }

    local height = elements.Text{
        x = 48, y = 0,
        shape = elements.shapes.Rectangle { w = 40,  h = 24 },
        colours = {
            line = {255, 255, 255, 255},
            fill = {  0,   0,   0, 255},
            text = {255, 255, 255, 255},
        },

        font = elements.Text.fonts.medium,
        text = "32",
    }

    local function create()
        local w, h = tonumber(width.text) or 32, tonumber(height.text) or 32
        local project = generators.project.default{w, h}
        
        new(project)
    end 

    local icon = elements.Button {
        x = 0, y = 0,
        image = elements.Button.Icon(project.icon),
        action = create,
    }

    local button = elements.Text {
        x = 96, y = 0,
        shape = elements.shapes.Rectangle { w = 92,  h = 24 },
        colours = {
            line = PALETTE.colours[1],
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

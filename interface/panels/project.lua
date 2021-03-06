local Class = require "hump.class"
local elements = require "interface.elements"

local ProjectPanel = Class {
    __includes = elements.Panel,
    name = "kooltool project panel",
    colours = elements.Panel.COLOURS.black,
}

function ProjectPanel:init(project, params)
    elements.Panel.init(self, {
        x = params.x, y = params.y,
        shape = elements.shapes.Rectangle { w = 448, h = 64, 
                                            anchor = params.anchor},
    })

    local icon = elements.Button{
        x = 0, y = 0,
        image = elements.Button.Icon(project.icon),
    }

    icon.actions["draw"] = true
    icon.actions["press"] = nil

    function icon:applyBrush(bx, by, brush, lock)
        brush:apply(project.icon, nil, bx, by)
    end

    function icon:sample(x, y)
        return {project.icon:getPixel(x, y)}
    end

    local title = elements.Text{
        x = 64, y = 0,

        shape = elements.shapes.Rectangle { w = 384, h = 32 - 4 },
        colours = {
            line = { 0, 0, 0, 0},
            fill = PALETTE.colours[1],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = project.name,
    }
    
    local description = elements.Text{
        x = 64, y = 32 - 4,

        shape = elements.shapes.Rectangle { w = 384, h = 32 + 4 },
        colours = {
            line = { 0, 0, 0, 0},
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

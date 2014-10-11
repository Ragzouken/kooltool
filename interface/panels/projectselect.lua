local Class = require "hump.class"
local elements = require "interface.elements"

local ProjectPanel = Class {
    __includes = elements.Panel,
    name = "kooltool project panel",
}

function ProjectPanel:init(project, i, project_clicked)
    elements.Panel.init(self, {
        shape = elements.shapes.Rectangle {x = 0,   y = (i - 1) * 64,
                                           w = 448, h = 64, 
                                           anchor = {0, 0}},
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
    
    local button = elements.Button{
        shape = elements.shapes.Rectangle { x = 64,  y = 0,
                                            w = 384, h = 64,
                                            anchor = {0, 0}},
        action = project_clicked,
    }
    
    self:add(icon)
    self:add(title)
    self:add(description)
    self:add(button)
end

local ProjectSelect = Class {
    __includes = elements.Panel,
    name = "kooltool project select",
    new_image = love.graphics.newImage("images/new_project.png"),
}

function ProjectSelect:init(editor)
    elements.Panel.init(self)

    self.editor = editor
end

function ProjectSelect:SetProjects(projects)
    self.projects = projects
    self.shape = elements.shapes.Rectangle {x = 32,  y = 32,
                                            w = 448, h = #self.projects * 64,
                                            anchor = {0, 0}}
    
    self:clear()
    
    for i, project in ipairs(projects) do
        local function project_clicked(event)
            self.editor:SetProject(project)
            self.active = false
        end
        
        self:add(ProjectPanel(project, i, project_clicked))
    end

    local project = {
        name = "new project",
        description = "create a blank new project",
        icon = ProjectSelect.new_image,
    }

    local function new()
        self.editor:SetProject()
        self.active = false
    end

    self:add(ProjectPanel(project, #projects + 1, new))
end

return ProjectSelect

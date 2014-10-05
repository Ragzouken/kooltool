local Class = require "hump.class"
local elements = require "interface.elements"

local ProjectPanel = Class { __includes = elements.Panel, }

function ProjectPanel:init(project, i, project_clicked)
    elements.Panel.init(self, {
        shape = elements.shapes.Rectangle(0, (i - 1) * 64, 448, 64, {-1, -1}),
    })
    
    local icon = elements.Button{
        x = 0, y = 0, w = 64, h = 64,
        icon = {image = project.icon, quad = love.graphics.newQuad(0, 0, 64, 64, 64, 64)},
    }
    
    local title = elements.Text{
        shape = elements.shapes.Rectangle(64, 0, 384, 32 - 4, {-1, -1}),
        colours = {
            stroke = PALETTE.colours[1],
            fill = PALETTE.colours[1],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.medium,
        text = project.name,
    }
    
    local description = elements.Text{
        shape = elements.shapes.Rectangle(64, 32 - 4, 384, 32 + 4, {-1, -1}),
        colours = {
            stroke = PALETTE.colours[2],
            fill = PALETTE.colours[2],
            text = {255, 255, 255, 255},
        },
        
        font = elements.Text.fonts.small,
        text = project.description,
    }
    
    local button = elements.Button{
        shape = elements.shapes.Rectangle(64, 0, 384, 64, {-1, -1}),
        action = project_clicked,
    }
    
    self:add(icon)
    self:add(title)
    self:add(description)
    self:add(button)
end

local ProjectSelect = Class {
    __includes = elements.Panel,
    new_image = love.graphics.newImage("images/new_project.png"),
}

function ProjectSelect:init(editor)
    elements.Panel.init(self)

    self.editor = editor
end

function ProjectSelect:SetProjects(projects)
    self.projects = projects
    self.shape = elements.shapes.Rectangle(32, 32, 448, #self.projects * 64, {-1, -1})
    
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

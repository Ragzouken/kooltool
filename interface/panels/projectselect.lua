local Class = require "hump.class"
local elements = require "interface.elements"

local ProjectPanel = require "interface.panels.project"
local NewProjectPanel = require "interface.panels.newproject"

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
    local function button(action)
        return elements.Button{
            shape = elements.shapes.Rectangle { x = 64,  y = 0,
                                                w = 384, h = 64,
                                                anchor = {0, 0}},
            action = action,
        }
    end

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

        local panel = ProjectPanel(project, { x = 0, y = (i - 1) * 64 })
        panel:add(button(project_clicked))
        self:add(panel)
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

    local panel = NewProjectPanel(project, { x = 0, y = #projects * 64 }, new)
    --panel:add(button(new))
    self:add(panel)
end

return ProjectSelect

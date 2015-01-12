local Class = require "hump.class"
local Timer = require "hump.timer"

local Panel = require "interface.elements.panel"
local Frame = require "interface.elements.frame"
local Text = require "interface.elements.text"

local shapes = require "interface.elements.shapes"

local elements = require "interface.elements"
local Toolbar = require "interface.panels.toolbar"

local Entity = require "components.entity"
local Notebox = require "components.notebox"

local tools = require "tools"

local Project = require "components.project"
local ProjectSelect = require "interface.panels.projectselect"
local ProjectPanel = require "interface.panels.project"
local Toolbox = require "interface.panels.toolbox"
local Button = require "interface.elements.button"

local generators = require "generators"
local colour = require "utilities.colour"

local Game = require "engine.game"
local savesound = love.audio.newSource("sounds/save.wav")
local nopesound = love.audio.newSource("sounds/nope.wav")

PALETTE = nil

local Editor = Class {
    __includes = Panel,
    name = "kooltool editor",
}

local function project_list()
    local projects = {}
    local proj_path = "projects"

    local items = love.filesystem.getDirectoryItems(proj_path, function(filename)
        local path = proj_path .. "/" .. filename

        if love.filesystem.isDirectory(path) then
            local project = Project(path)
            project.name = path:match("[^/]+$")
            project:preview()

            table.insert(projects, project)
        end
    end)

    local tutorial = Project("tutorial")
    tutorial.name = "tutorial"
    tutorial:preview()
    table.insert(projects, 1, tutorial)

    return projects
end


function Editor:init(camera)
    Panel.init(self, { shape = shapes.Plane{} })
    
    PALETTE = generators.Palette.generate(9)
    
    self.nocanvas = Text{
        shape = elements.shapes.Rectangle {x = 32+4, y = 0,
                                           w = 512-16,  h = 24,
                                           anchor = {0, 0}},
        colours = {
            stroke = {255,   0,   0, 255},
            fill =   {192,   0,   0, 255},
            text =   {255, 255, 255, 255},
        },
        
        font = Text.fonts.small,
        text = "WARNING| pixel edit may misbehave due to unsupported features\n"
            .. "-------' please email ragzouken@gmail.com or tweet @ragzouken",
    }

    self.nocanvas.active = NOCANVAS

    self.select = ProjectSelect(self)
    
    self.view = Frame { camera = camera, }

    self.toolbar = Toolbar {
        x=1, y=1, 
        buttons={},
        anchor={ 1, -1},
        size={0, 0},
    }

    self.thingbar = Toolbar {
        x=1, y=1, 
        buttons={},
        anchor={ 1, -1},
        size={0, 0},
    }

    self.filebar = Toolbar {
        x=1, y=1, 
        buttons={},
        anchor={ 1, -1},
        size={0, 0},
    }

    self:add(self.select, -math.huge)
    self:add(self.view)
    self:add(self.nocanvas, -math.huge)
    
    self:add(self.toolbar,  -math.huge)
    self:add(self.thingbar, -math.huge)
    self:add(self.filebar,  -math.huge)

    self.tooltip = Text {
        x = 48, y = 0,

        shape = elements.shapes.Rectangle { w = 512,  h = 24 },
        colours = {
            stroke = {  0,   0,   0, 255},
            fill =   {  0,   0,   0, 255},
            text =   {255, 255, 255, 255},
        },

        font = Text.fonts.medium,
        text = "",
    }

    self:add(self.tooltip, -math.huge)

    self.select:SetProjects(project_list())
end

function Editor:SetProject(project)
    self.project = project

    self.select.active = false

    self.view:clear()
    self.view:add(project, -1)

    self.view.camera:lookAt(128, 128)

    local projectedit = ProjectPanel(project, { x = 128, y = -256 })
    projectedit.actions["drag"] = true
    project.layers.surface:add(projectedit)

    local function icon(path)
        return Button.Icon(love.graphics.newImage(path))
    end

    local buttons = {
        {icon("images/drag.png"), function()
            self.active = self.tools.drag
        end, "move objects"},
    }
    
    local things = {
    {icon("images/entity.png"), function(button, event)
        local sx, sy, wx, wy = unpack(event.coords)
        local target, x, y = self:target("entity", sx, sy)

        local entity = Entity()
        target:addEntity(entity)
        entity:blank(x, y)

        self.action = self.tools.drag
        self.action:grab(entity, sx, sy)
    end, "drag to create a new character"},
    {icon("images/note.png"), function(button, event)
        local sx, sy, wx, wy = unpack(event.coords)
        local target, x, y = self:target("note", sx, sy)

        local notebox = Notebox(target)
        notebox:blank(x, y, "[note]")
        target:addNotebox(notebox)

        self.action = self.tools.drag
        self.action:grab(notebox, sx, sy)

        self.focus = notebox
    end, "drag to create a new note"},
    }

    local files = {
    {icon("images/play.png"), function()
        savesound:play()
        self.project:save("projects/" ..self.project.name)
        
        MODE = Game(self.project, true)
    end, "playtest"},
    ---[[
    {icon("images/save.png"), function()
        if not self.export_thread then
            savesound:play()
            self.project:save("projects/" .. self.project.name)
            love.system.openURL("file://"..love.filesystem.getSaveDirectory())
        else
            nopesound:play()
        end
    end, "save"},
    {icon("images/export.png"), function()
        if not self.export_thread then
            savesound:play()
            self.project:save("projects/" ..self.project.name)

            self.export_thread = love.thread.newThread("utilities/export.lua")
            self.export_thread:start(self.project.name)
        else
            nopesound:play()
        end
    end, "export"},
    --]]
    }

    self.toolbar:init  { x=1, y=1, buttons = buttons, anchor = {0, 0}, size = {32, 32} }
    self.thingbar:init { x=1, y=love.window.getHeight(), buttons = things, anchor = {0, 0}, size = {32, 32} }
    self.filebar:init  { x=0, y=0, buttons = files, anchor = {0, 0}, size = {32, 32} }

    self.action = nil
    self.active = nil
    self.focus = nil

    self.tools = {
        pan = tools.Pan(self.view.camera),
        drag = tools.Drag(self),
        draw = tools.Draw(self, PALETTE.colours[3]),
        tile = tools.Tile(self, project, 1),
        wall = tools.Wall(self, project),
        marker = tools.Marker(self),
    }

    self.active = self.tools.drag

    if self.toolbox then self:remove(self.toolbox) end
    self.toolbox = Toolbox { editor=self }
    self:add(self.toolbox, -math.huge)

    self.toolindex = {
        [self.tools.drag] = 1,
    }

    self.global = {
        self.tools.pan,
    }
end

function Editor:update(dt)
    Panel.update(self, dt)

    self.select:move_to { x = love.window.getWidth() / 2, y = 32, anchor = {0.5, 0} }

    if self.export_thread and not self.export_thread:isRunning() then
        self.export_thread = nil
    end

    if self.project then
         self.toolbar:move_to { x = 1, y =   1 }
        self.thingbar:move_to { x = 1, y = 176-132 }
         self.filebar:move_to { x = 1, y = 252-132 }

        if self.toolindex[self.active] then self.toolbar.group:select(self.toolbar.buttons[self.toolindex[self.active]]) end

        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        for name, tool in pairs(self.tools) do
            tool:update(dt, sx, sy, wx, wy)
        end

        if self.active then
            --self.toolname.text = self.active.name
        end

        self.project:update(dt)
        colour.walls(dt, 0)

        -- tilebar
        local tiles = {}
        local tileset = self.project.layers.surface.tileset
        
        for i, quad in ipairs(tileset.quads) do
            local function action()
                self.active = self.tools.tile
                self.tools.tile.tile = i
            end
            
            table.insert(tiles, {Button.Icon(tileset.canvas, quad), action})
        end

        self.toolbox:set_tiles(tiles)

        if not self.focus then
            local scale = self.view.camera.scale
            local pans = { left = {-1, 0}, right = {1, 0}, up = {0, -1}, down = {0, 1}}

            if not love.keyboard.isDown("lshift", "rshift") then
                for key, vector in pairs(pans) do
                    local vx, vy = unpack(vector)
                    if love.keyboard.isDown(key) then self.view.camera:move(vx / scale * 4, vy / scale * 4) end
                end
            end
        end 
    end
end

function Editor:cursor(sx, sy, wx, wy)
    local function cursor(tool)
        local cursor = tool:cursor(sx, sy, wx, wy)

        if cursor then
            love.mouse.setCursor(cursor)
            return true
        end

        return false
    end

    local tooltip = self:target("tooltip", sx, sy)

    self.tooltip.text = tooltip and tooltip.tooltip or ""
    self.tooltip.active = tooltip
    self.tooltip:refresh()

    if self:target("press", sx, sy) then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        return
    end

    if love.keyboard.isDown("tab") and cursor(self.tools.drag) then return end

    if self.action and cursor(self.action) then return end
    if self.active and cursor(self.active) then return end

    for name, tool in pairs(self.global) do
        if cursor(tool) then return end
    end

    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
end

function Editor:input(callback, ...)
    local function input(tool, ...)
        local block, change = tool[callback](tool, ...)

        if tool == self.action and change == "end" then
            self.action = nil
        elseif not self.action and change == "begin" then
            self.action = tool
        end
        
        if block then
            return true
        else
            return false
        end
    end

    if love.keyboard.isDown(unpack(BINDINGS("drag", "tab"))) and input(self.tools.drag, ...) then return true end

    if self.action and input(self.action, ...) then return true end
    if self.active and input(self.active, ...) then return true end

    for i, tool in ipairs(self.global) do
        if input(tool, ...) then return true end
    end

    return false
end

local medium = love.graphics.newFont("fonts/PressStart2P.ttf", 8)
local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

function Editor:draw(params)
end

function Editor:draw_above(params)
    if self.project then
        self.view.camera:attach()

        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()
        self:cursor(sx, sy, wx, wy)

        self.view.camera:detach()
    end
end

function Editor:mousepressed(sx, sy, button)
    if self.focus then
        self.focus:defocus()
        self.focus = nil
    end

    local wx, wy = self.view.camera:worldCoords(sx, sy)

    local target = self:target("press", sx, sy)

    if target and button == "l" then
        target:event{ action = "press", coords = {sx, sy, wx, wy} }
        return
    end

    local target = self:target("script", sx, sy)
    if target and button == "l" and love.keyboard.isDown("s") then
        target.script.active = not target.script.active
        return
    end

    local target = self:target("type", sx, sy)
    if target and button == "l" then
        self.focus = target
        target:focus()
    end

    if self.project then
        if self:input("mousepressed", button, sx, sy, wx, wy) then
            return
        end
    end
end

function Editor:mousereleased(x, y, button)    
    if self.project then
        local wx, wy = self.view.camera:worldCoords(x, y)

        self:input("mousereleased", button, x, y, wx, wy)
    end
end

function Editor:keypressed(key, isrepeat)
    if key == "f11" and not isrepeat then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    end

    if key == "f2" and not isrepeat then
        self.view:print()
    end

    if key == "escape" and self.focus then
        self.focus:defocus()
        self.focus = nil
        return
    end

    if key == "escape" and self.project then
        self.select.active = not self.select.active
        self.select:SetProjects(project_list())
        return
    end

    if self.focus then self.focus:keypressed(key, isrepeat) return true end

    if self.project then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        if key == " " and not isrepeat then
            self.toolbox:move_to { x = math.floor(sx), y = math.floor(sy), anchor = { 0.5, 0.5 } }
            self.toolbox.active = true
            return true
        end

        if key == "q" then self.active = self.tools.draw   return true end
        if key == "w" then self.active = self.tools.tile   return true end
        if key == "e" then self.active = self.tools.wall   return true end
        if key == "r" then self.active = self.tools.marker return true end

        self:input("keypressed", key, isrepeat, sx, sy, wx, wy)
    end
end

function Editor:keyreleased(key)
    if self.project then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        if key == " " then
            self.toolbox:move_to { x = sx, y = sy }
            self.toolbox.active = false
            return true
        end

        self:input("keyreleased", key, sx, sy, wx, wy)
    end
end

function Editor:textinput(character)
    if self.focus then self.focus:typed(character) end

    if self.project then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        self:input("textinput", character, sx, sy, wx, wy)
    end
end

return Editor

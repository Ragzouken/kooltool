local Class = require "hump.class"
local Timer = require "hump.timer"

local Panel = require "interface.elements.panel"
local Frame = require "interface.elements.frame"
local Text = require "interface.elements.text"

local elements = require "interface.elements"
local Toolbar = require "interface.panels.toolbar"

local tools = require "tools"

local Project = require "components.project"
local ProjectSelect = require "interface.panels.projectselect"

local generators = require "generators"
local colour = require "utilities.colour"

local Game = require "engine.game"
local savesound = love.audio.newSource("sounds/save.wav")

PALETTE = nil

local Editor = Class { __includes = Panel, }

function Editor:init(project)
    Panel.init(self)
    
    PALETTE = generators.Palette.generate(3)

    local projects = {}
    local proj_path = "projects"

    local items = love.filesystem.getDirectoryItems(proj_path, function(filename)
        local path = proj_path .. "/" .. filename

        if love.filesystem.isDirectory(path) then
            local project = Project(path)
            project:loadIcon(path)

            table.insert(projects, project)
        end
    end)

    local tutorial = Project("tutorial")
    tutorial:loadIcon("tutorial")
    table.insert(projects, 1, tutorial)
    
    --PROJECTS = projects
    
    self.nocanvas = Text{
        shape = elements.shapes.Rectangle(32+4, 0, 512, 32 + 4, {-1, -1}),
        colours = {
            stroke = {255,   0,   0, 255},
            fill =   {192,   0,   0, 255},
            text =   {255, 255, 255, 255},
        },
        
        font = Text.fonts.small,
        text = "WARNING| pixel edit may misbehave due to unsupported features\n"
            .. "-------' please email ragzouken@gmail.com or tweet @ragzouken",
    }

    self.toolname = Text{
        shape = elements.shapes.Rectangle(32+4, 0, 512, 32 + 4, {-1, -1}),
        colours = {
            stroke = {  0,   0,   0, 255},
            fill =   {  0,   0,   0, 255},
            text =   {255, 255, 255, 255},
        },

        font = Text.fonts.medium,
        text = "",
    }

    self.nocanvas.active = NOCANVAS

    self.select = ProjectSelect(self)
    self.select:SetProjects(projects)
    
    self.view = Frame()

    self.tilebar = Toolbar {
        x=1, y=1, 
        buttons={},
        anchor={ 1, -1},
        size={0, 0},
    }

    self.tilebar.active = false

    self:add(self.select, -math.huge)
    self:add(self.view)
    self:add(self.nocanvas, -math.huge)
    self:add(self.toolname, -math.huge)
    self:add(self.tilebar,  -math.huge)

    self.view.camera = CAMERA
end

function Editor:SetProject(project)
    self.project = SETPROJECT(project, self.view.camera)
    
    local project = self.project

    self.view:clear()
    self.view:add(project.layers.surface, -1)
    self.view:add(project.layers.annotation, -2)

    self.tilebar.active = true

    local function icon(path)
        local image = love.graphics.newImage(path)
        local w, h = image:getDimensions()
        
        return {
            image = image,
            quad = love.graphics.newQuad(0, 0, w, h, w, h),
        }
    end
    
    local buttons = {
    {icon("images/pencil.png"), function()
        self.active = self.tools.draw
    end},
    {icon("images/tiles.png"), function()
        self.active = self.tools.tile
    end},
    {icon("images/walls.png"), function()
        self.active = self.tools.wall
    end},
    {icon("images/marker.png"), function()
        self.active = self.tools.marker
    end},
    {icon("images/entity.png"), function(button, event)
        local sx, sy, wx, wy = unpack(event.coords)
        local entity = self.project:newEntity(wx, wy)
        self.action = self.tools.drag
        self.action:grab(entity, sx, sy, wx, wy)
    end},
    {icon("images/note.png"), function(button, event)
        local sx, sy, wx, wy = unpack(event.coords)
        local notebox = self.project:newNotebox(wx, wy)
        self.action = self.tools.drag
        self.action:grab(notebox, sx, sy, wx, wy)
    end},
    {icon("images/save.png"), function()
        savesound:play()
        self.project:save("projects/" .. self.project.name)
        love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    end},
    {icon("images/export.png"), function()
        savesound:play()
        self.project:save("projects/" ..self.project.name)
        
        MODE = Game(self.project)

        --toolbar.interface.project:export()
        --love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/releases/" .. PROJECT.name)
    end},
    }
    
    self.toolbar = Toolbar{x=1, y=1, buttons=buttons, anchor={-1, -1}, size={32, 32}}
    
    self:add(self.toolbar, -math.huge)

    self.action = nil
    self.active = nil

    self.tools = {
        pan = tools.Pan(self.view.camera),
        drag = tools.Drag(project),
        draw = tools.Draw(project, PALETTE.colours[3]),
        tile = tools.Tile(project, 1),
        wall = tools.Wall(project),
        marker = tools.Marker(project),
    }

    self.global = {
        self.tools.pan,
        self.tools.drag,
    }
end

function Editor:update(dt)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        for name, tool in pairs(self.tools) do
            tool:update(dt, sx, sy, wx, wy)
        end

        if self.active then
            self.toolname.text = self.active.name
        end

        PROJECT:update(dt)
        colour.walls(dt, 0)

        -- tilebar
        local tiles = {}
        local tileset = PROJECT.layers.surface.tileset
        
        for i, quad in ipairs(tileset.quads) do
            local function action()
                self.active = self.tools.tile
                self.tools.tile.tile = i
            end
            
            table.insert(tiles, {{image = tileset.canvas,
                                  quad = quad},
                                 action})
        end
        
        self.tilebar:init {
            x=love.window.getWidth() - 1, y=1,
            buttons=tiles,
            anchor={1, -1},
            size=PROJECT.layers.surface.tileset.dimensions
        }
    end
end

function Editor:cursor(sx, sy, wx, wy)
    local function cursor(tool)
        local cursor = tool:cursor(sx, sy, wx, wy)

        if cursor then
            love.window.setCursor(cursor)
            return true
        end

        return false
    end

    if self.action and cursor(self.action) then return end
    if self.active and cursor(self.active) then return end

    for name, tool in pairs(self.global) do
        if cursor(tool) then return end
    end
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

    if self.action and input(self.action, ...) then return true end
    if self.active and input(self.active, ...) then return true end

    for i, tool in ipairs(self.global) do
        if input(tool, ...) then return true end
    end

    return false
end

local medium = love.graphics.newFont("fonts/PressStart2P.ttf", 8)
local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

function Editor:draw()
    Panel.draw(self)

    if PROJECT then
        self.view.camera:attach()

        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()
        self:cursor(sx, sy, wx, wy)

        self.view.camera:detach()
    end
end

function Editor:mousepressed(sx, sy, button)
    local wx, wy = self.view.camera:worldCoords(sx, sy)
    
    local event = { action = "press", coords = {sx, sy, wx, wy}, }
    local target = self:target("press", sx, sy)

    if target then
        target:event(event)
        return
    end

    if PROJECT then
        if self:input("mousepressed", button, sx, sy, wx, wy) then
            return
        end
    end
end

function Editor:mousereleased(x, y, button)    
    if PROJECT then
        local wx, wy = self.view.camera:worldCoords(x, y)

        self:input("mousereleased", button, x, y, wx, wy)
    end
end

function Editor:keypressed(key, isrepeat)
    if PROJECT then
        if key == "f11" and not isrepeat then
            love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        end

        if key == "escape" and PROJECT then
            self.select.active = not self.select.active
            return
        end

        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        self:input("keypressed", key, isrepeat, sx, sy, wx, wy)
    end
end

function Editor:keyreleased(key)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        self:input("keyreleased", key, sx, sy, wx, wy)
    end
end

function Editor:textinput(character)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = self.view.camera:mousepos()

        self:input("textinput", character, sx, sy, wx, wy)
    end
end

return Editor

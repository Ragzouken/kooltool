local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Toolbar = require "interface.toolbar"
local Tilebar = require "interface.tilebar"

local Test = require "interface.interface_real"
local shapes = require "interface.elements.shapes"

local Toolbar_ = require "interface.panels.toolbar"

local tools = require "tools"

local Game = require "engine.game"
local Interface_ = require "interfacewrong"
local savesound = love.audio.newSource("sounds/save.wav")

local Interface = Class {}

function Interface:init(project)
    self.project = project

    self.panes = {
    }
    
    --self:addChild(Tilebar(self))

    self.action = nil
    self.active = nil

    self.tools = {
        pan = tools.Pan(CAMERA),
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
        INTERFACE_.active = INTERFACE_.tools.draw
    end},
    {icon("images/tiles.png"), function()
        INTERFACE_.active = INTERFACE_.tools.tile
    end},
    {icon("images/walls.png"), function()
        INTERFACE_.active = INTERFACE_.tools.wall
    end},
    {icon("images/marker.png"), function()
        INTERFACE_.active = INTERFACE_.tools.marker
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
        INTERFACE_.project:save("projects/" .. INTERFACE_.project.name)
        love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    end},
    {icon("images/export.png"), function()
        savesound:play()
        INTERFACE_.project:save("projects/" ..INTERFACE_.project.name)
        
        INTERFACE = Interface_({})
        MODE = Game(INTERFACE_.project)

        --toolbar.interface.project:export()
        --love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/releases/" .. PROJECT.name)
    end},
    }
    
    TEST = Panel{}
    
    self.toolbar = Toolbar_{x=1.5, y=1.5, buttons=buttons, anchor={-1, -1}}
    self.tilebar = Toolbar_{x=1.5, y=1.5, buttons=buttons, anchor={ 1, -1}}
    
    TEST:add(self.toolbar)
    TEST:add(self.tilebar)
end

function Interface:update(dt, sx, sy, wx, wy)
    local tiles = {}
    local tileset = self.project.layers.surface.tileset
    
    for i, quad in ipairs(tileset.quads) do
        local function action()
            self.active = self.tools.tile
            self.tools.tile.tile = i
            print("poo", i)
        end
        
        table.insert(tiles, {{image = tileset.canvas,
                              quad = quad},
                             action})
    end
    
    self.tilebar:init{x=love.window.getWidth() - 1.5, y=1.5, buttons=tiles, anchor={1, -1}}
    
    for name, tool in pairs(self.tools) do
        tool:update(dt, sx, sy, wx, wy)
    end
end

function Interface:draw()
    for i, pane in ipairs(self.panes) do
        --pane:draw()
    end
    
    TEST:draw()
end

function Interface:cursor(sx, sy, wx, wy)
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

function Interface:input(callback, ...)
    if callback == "mousereleased" or callback == "mousepressed" then
        local b, sx, sy, wx, wy = unpack{...}
        local event = { action = "press", coords = {sx, sy, wx, wy}, }
        
        local target = TEST:target("press", sx, sy)
        
        if target then
            target:event(event)
            return true
        end
    end

    
    for i, pane in ipairs(self.panes) do
        if pane[callback] and pane[callback](pane, ...) then return true end
    end
    
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

return Interface

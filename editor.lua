local Class = require "hump.class"
local Timer = require "hump.timer"

local Panel = require "interface.elements.panel"
local Project = require "components.project"
local ProjectSelect = require "interface.panels.projectselect"

local interface = require "interface"
local generators = require "generators"
local colour = require "utilities.colour"

PALETTE = nil
POO = nil
INTERFACE = nil
INTERFACE_ = nil
PROJECTS = nil

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
    
    PROJECTS = projects
    
    self.select = ProjectSelect()
    self.select:SetProjects(projects)
    
    self:add(self.select)
end

function Editor:update(dt)
    if PROJECT and not INTERFACE_ then
        INTERFACE_ = interface.Interface(PROJECT)
    end

    local sx, sy = love.mouse.getPosition()
    local wx, wy = CAMERA:mousepos()

    if INTERFACE_ then INTERFACE_:update(dt, sx, sy, wx, wy) end

    colour.walls(dt, 0)

    if CAMERA.scale % 1 == 0 then CAMERA.x, CAMERA.y = math.floor(CAMERA.x), math.floor(CAMERA.y) end

    if PROJECT then
        PROJECT:update(dt)
    end
end

local medium = love.graphics.newFont("fonts/PressStart2P.ttf", 8)
local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

function Editor:draw()
    if PROJECT then
        CAMERA:attach()

        PROJECT:draw(true)
        
        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()
        INTERFACE_:cursor(sx, sy, wx, wy)

        CAMERA:detach()

        if INTERFACE_.active then
            local o = 4-1+32+2
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(0, 0, 0, 255)
            love.graphics.rectangle("fill", 0, 0, 512, 16 + 3)
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.setFont(large)
            love.graphics.print(" " .. INTERFACE_.active.name, 3+o, 5)
        end

        INTERFACE_:draw()
    end

    if NOCANVAS then
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("fill", 0, 17, 512, 19)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.setFont(medium)
        love.graphics.print(" WARNING: pixel edit may misbehave due to unsupported features", 1, 4+16)
        love.graphics.print("          please email ragzouken@gmail.com or tweet @ragzouken", 1, 4+16+9)
    end

    love.graphics.setColor(255, 255, 255, 255)
    
    Panel.draw(self)
end

function Editor:mousepressed(sx, sy, button)
    local wx, wy = CAMERA:worldCoords(sx, sy)
    
    if PROJECT then
        if INTERFACE_:input("mousepressed", button, sx, sy, wx, wy) then
            return
        end
    end
    
    local event = { action = "press", coords = {sx, sy, wx, wy}, }
    local target = self:target("press", sx, sy)
    
    if target then
        target:event(event)
    end
end

function Editor:mousereleased(x, y, button)    
    if PROJECT then
        local wx, wy = CAMERA:worldCoords(x, y)

        INTERFACE_:input("mousereleased", button, x, y, wx, wy)
    end
end

function Editor:keypressed(key, isrepeat)
    if PROJECT then
        if key == "f11" and not isrepeat then
            love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        end

        if key == "escape" and PROJECT then
            INTERFACE_.ps.active = not INTERFACE_.ps.active
            return
        end

        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()

        INTERFACE_:input("keypressed", key, isrepeat, sx, sy, wx, wy)
    end
end

function Editor:keyreleased(key)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()

        INTERFACE_:input("keyreleased", key, sx, sy, wx, wy)
    end
end

function Editor:textinput(character)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()

        INTERFACE_:input("textinput", character, sx, sy, wx, wy)
    end
end

return Editor

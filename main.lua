do
    require "utilities.strict"

    class_commons = nil
    common = nil
    NOCANVAS = not love.graphics.isSupported("canvas")
    
    MODE = nil
    EDITOR = nil
end

love.graphics.setDefaultFilter("nearest", "nearest")

if NOCANVAS then
    require "utilities.nocanvas"
end

local Camera = require "hump.camera"
local Editor = require "editor"
local Game = require "engine.game"
local Project = require "components.project"
local generators = require "generators"

function love.load(arg)
    io.stdout:setvbuf('no')
    
    love.keyboard.setKeyRepeat(true)
    local camera = Camera(128, 128, 2)

    if love.filesystem.isDirectory("embedded") then
        local project = Project("embedded")
        project = project:load()

        EDITOR = Editor(project, camera)
        MODE = Game(project)
    else
        MODE = Editor(camera)
        EDITOR = MODE
    end
end

function love.update(dt)
    MODE:update(dt)

    if MODE.project then
        love.window.setTitle(string.format("kooltool sketch (%s) [%s]", MODE.project.name, love.timer.getFPS()))
    end
end

local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

function love.draw()
    MODE:draw_tree{}

    if EDITOR and MODE ~= EDITOR and MODE.playtest then
        local o = 4-1+2
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", 0, 0, 512, 16 + 3)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setFont(large)
        love.graphics.print("press escape to end playtest", 3+o, 5)
    end
end

function love.mousepressed(...)
    MODE:mousepressed(...)
end

function love.mousereleased(...)    
    MODE:mousereleased(...)
end

function love.keypressed(...)
    if (function (key, irepeat)
        if key == "escape" and EDITOR and MODE ~= EDITOR and MODE.playtest then
            MODE:undo()
            MODE = EDITOR
            return true
        elseif key == "f12" then
            local project = Project()
            project.name = "tutorial"
            EDITOR:SetProject(project)
            MODE = EDITOR
            return true
        end
    end)(...) then return end

    MODE:keypressed(...)
end

function love.keyreleased(...)
    MODE:keyreleased(...)
end

function love.textinput(...)
    MODE:textinput(...)
end

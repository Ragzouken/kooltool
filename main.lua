do
    require "utilities.strict"

    class_commons = nil
    common = nil
    NOCANVAS = not love.graphics.isSupported("canvas")
    
    PROJECT = nil
    MODE = nil
    EDITOR = nil
    TILESIZE = nil
end

if jit then require "utilities.imagedata-ffi" end

love.graphics.setDefaultFilter("nearest", "nearest")

if NOCANVAS then
    require "utilities.nocanvas"
end

local Camera = require "hump.camera"
local Editor = require "editor"
local Game = require "engine.game"
local Project = require "components.project"

function love.load(arg)
    --if arg[#arg] == "-debug" then
    --    require("mobdebug").start()
    --end
    
    local tw = arg[1] and tonumber(arg[1]) or 32
    local th = arg[2] and tonumber(arg[2]) or tw
    
    TILESIZE = {tw, th}
    
    io.stdout:setvbuf('no')
    
    love.keyboard.setKeyRepeat(true)
    local camera = Camera(128, 128, 2)

    if love.filesystem.isDirectory("embedded") then
        local project = Project()
        project.name = "embedded"

        SETPROJECT(project, camera)

        EDITOR = Editor(PROJECT, camera)
        MODE = Game(PROJECT)
    else
        MODE = Editor(PROJECT, camera)
        EDITOR = MODE
    end
end

function SETPROJECT(project, camera)
    if project then
        local path

        if project.name == "kooltoolrial" then
            path = "tutorial"
        elseif project.name == "embedded" then
            path = project.name
        else
            path = "projects/" .. project.name
        end

        PROJECT = project:load(path) or project
    else
        PROJECT = Project()
        PROJECT.name = Project.name_generator:generate():gsub(" ", "_")
        PROJECT:blank(TILESIZE)
    end

    love.window.setTitle(string.format("kooltool sketch (%s)", PROJECT.name))
    
    camera:lookAt(128, 128)

    return PROJECT
end

function love.update(dt)
    MODE:update(dt)

    if PROJECT then love.window.setTitle(string.format("kooltool sketch (%s) [%s]", PROJECT.name, love.timer.getFPS())) end
end

local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

function love.draw()
    MODE:draw()

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

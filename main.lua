do
    require "utilities.strict"

    class_commons = nil
    common = nil
    CAMERA = nil
    PROJECT = nil
    NOCANVAS = not love.graphics.isSupported("canvas")
    INTERFACE = nil
    INTERFACE_ = nil
    MODE = nil
    EDITOR = nil
end

if jit then require "utilities.imagedata-ffi" end

love.graphics.setDefaultFilter("nearest", "nearest")

if NOCANVAS then
    require "utilities.nocanvas"
end

local Camera = require "hump.camera"
local Editor = require "editor"
local Game = require "engine.game"
local Project = require "project"
local Interface = require "interfacewrong"

function love.load()
    love.keyboard.setKeyRepeat(true)
    CAMERA = Camera(128, 128, 2)

    if love.filesystem.isDirectory("embedded") then
        INTERFACE = Interface({})
        SETPROJECT(Project("embedded"))

        MODE = Game(PROJECT)
    else
        MODE = Editor(PROJECT)
        EDITOR = MODE
    end
end

function SETPROJECT(project)
    if project then
        PROJECT = project
        local path

        if project.name == "tutorial" or project.name == "embedded" then
            path = project.name
        else
            path = "projects/" .. project.name
        end

        PROJECT:load(path)
    else
        PROJECT = Project.default(Project.name_generator:generate():gsub(" ", "_"))
    end

    INTERFACE.draw = function() end

    love.window.setTitle("kooltool sketch (" .. PROJECT.name .. ")")
end

function love.update(dt)
    MODE:update(dt)
end

function love.draw()
    MODE:draw()
end

function love.mousepressed(...)
    MODE:mousepressed(...)
end

function love.mousereleased(...)    
    MODE:mousereleased(...)
end

function love.keypressed(...)
    (function (key, irepeat)
        if key == "escape" and EDITOR and MODE ~= EDITOR then
            MODE = EDITOR
        end
    end)(...)

    MODE:keypressed(...)
end

function love.keyreleased(...)
    MODE:keyreleased(...)
end

function love.textinput(...)
    MODE:textinput(...)
end

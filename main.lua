do
    require "utilities.strict"

    class_commons = nil
    common = nil
    CAMERA = nil
    ZOOM = nil
    PROJECT = nil
    NOCANVAS = not love.graphics.isSupported("canvas")
    INTERFACE = nil
    INTERFACE_ = nil
end

if jit then require "utilities.imagedata-ffi" end

love.graphics.setDefaultFilter("nearest", "nearest")

if NOCANVAS then
    require "nocanvas"
end

local Camera = require "hump.camera"
local Project = require "project"
local Interface = require "interfacewrong"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    love.keyboard.setKeyRepeat(true)
    CAMERA = Camera(128, 128, 2)
    ZOOM = 2

    if love.filesystem.isDirectory("embedded") then
        INTERFACE = Interface({})
        SETPROJECT(Project("embedded"))

        require "play"
    else
        require "edit"
    end

    love.load()
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

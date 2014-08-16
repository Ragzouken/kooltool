if jit then require "utilities.imagedata-ffi" end

love.graphics.setDefaultFilter("nearest", "nearest")

if not love.graphics.isSupported("canvas") then
    require "nocanvas"
end

local Camera = require "hump.camera"
local Project = require "project"
local Interface = require "interface"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    --love.mouse.setCursor(love.mouse.newCursor("images/pencil.png", 0, 0))

    --love.filesystem.mount("projects", "saved_projects")
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

    MODE = PIXELMODE
    INTERFACE.draw = function() end
end

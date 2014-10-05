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
    TEST = nil
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
local interface = require "interface"

function love.load(arg)
    --if arg[#arg] == "-debug" then
    --    require("mobdebug").start()
    --end
    
    local tw = arg[1] and tonumber(arg[1]) or 32
    local th = arg[2] and tonumber(arg[2]) or tw
    
    TILESIZE = {tw, th}
    
    io.stdout:setvbuf('no')
    
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
        PROJECT = Project.default(Project.name_generator:generate():gsub(" ", "_"), TILESIZE)
    end

    love.window.setTitle("kooltool sketch (" .. PROJECT.name .. ")")
    
    CAMERA:lookAt(128, 128)
end

function love.update(dt)
    MODE:update(dt)
end

local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

function love.draw()
    MODE:draw()

    if EDITOR and MODE ~= EDITOR then
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
    (function (key, irepeat)
        if key == "escape" and EDITOR and MODE ~= EDITOR then
            MODE:undo()
            MODE = EDITOR
        elseif key == "f12" then
            SETPROJECT(Project("tutorial"))
            EDITOR = Editor(PROJECT)
            MODE = EDITOR
            INTERFACE_ = interface.Interface(PROJECT)
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

love.graphics.setDefaultFilter("nearest", "nearest")

local Camera = require "hump.camera"
local Timer = require "hump.timer"
local Interface = require "interface"
local Palette = require "palette"
local Project = require "project"
local EditMode = require "editmode"

local colour = require "colour"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    love.filesystem.mount(".", "projects")
    love.keyboard.setKeyRepeat(true)

    PALETTE = Palette.generate(3)
    TILE = 1
    FULL = false
    BRUSHSIZE = 1
    CAMERA = Camera(128, 128, 2)

    TILESOUND = love.audio.newSource("sounds/marker pen.wav")
    TIMER = Timer()
    ZOOM = 2

    local projects = {}

    local items = love.filesystem.getDirectoryItems("projects", function(filename)
        if love.filesystem.isDirectory(filename) then
            local project = Project(filename)
            project:loadIcon(filename)

            projects[#projects+1] = project
        end
    end)

    local tutorial = Project("tutorial")
    tutorial:loadIcon("tutorial")
    table.insert(projects, 1, tutorial)

    INTERFACE = Interface(projects)
    MODE = INTERFACE.modes.select_project
end

function SETPROJECT(project)
    if project then
        PROJECT = project
        local path = project.name == "tutorial" and "tutorial" or "projects/" .. project.name
        PROJECT:load(path)
    else
        PROJECT = Project.default(Project.name_generator:generate())
    end

    MODE = PROJECT.tilelayer.modes.pixel
    INTERFACE.draw = function() end

    print(PROJECT.name)
end

function love.update(dt)
    --require("lovebird").update()

    TIMER:update(dt)
    
    if PROJECT then
        PROJECT:update(dt)

        local mx, my = CAMERA:mousepos()
        mx, my = math.floor(mx), math.floor(my)

        MODE:hover(mx, my, dt)

        if love.mouse.isDown("m") and DRAG then
            local mx, my = love.mouse.getPosition()
            local x, y, cx, cy = unpack(DRAG)

            local dx, dy = mx - x, my - y
            local s = CAMERA.scale

            CAMERA:lookAt(cx - dx / s, cy - dy / s)
        end
    end
end

function love.draw()
    if PROJECT then
        CAMERA:attach()

        PROJECT.tilelayer:draw()

        local mx, my = CAMERA:mousepos()
        love.graphics.setColor(colour.random())

        love.graphics.push()
        love.graphics.scale(0.5)
        PROJECT.notelayer:draw()
        love.graphics.pop()

        MODE:draw(mx, my)

        CAMERA:detach()

        PROJECT.tilelayer.tileset:draw()
        love.graphics.print(MODE.name, 3, 5)

        INTERFACE:draw()
    else
        INTERFACE:draw()
        MODE:draw()
    end
end

local dirs = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function love.mousepressed(x, y, button)
    local mx, my = CAMERA:worldCoords(x, y)
    mx, my = math.floor(mx), math.floor(my)

    if PROJECT then
        if button == "l" and MODE == PROJECT.tilelayer.modes.tile then
            local index = PROJECT.tilelayer.tileset:click(x, y)
            if index then TILE = index return true end
        end
    end

    if MODE:mousepressed(mx, my, button) then return end

    if PROJECT then
        if button == "m" then
            DRAG = {x, y, CAMERA.x, CAMERA.y}
        elseif button == "wu" then
            if TWEEN then TIMER:cancel(TWEEN) end
            ZOOM = math.min(ZOOM * 2, 16)
            
            local ox, oy, oz = CAMERA.x, CAMERA.y, CAMERA.scale
            local dx, dy, dz = CAMERA.x - mx, CAMERA.y - my, ZOOM - oz
            local t = 0

            local oscale = CAMERA.scale
            local factor = ZOOM / CAMERA.scale

            TWEEN = TIMER:do_for(0.25, function(dt)
                t = t + dt
                local u = t / 0.25
                local du = factor - 1

                CAMERA.scale = oscale*factor - (1 - u) * dz
                CAMERA.x, CAMERA.y = mx + dx / (1 + du*u), my + dy / (1 + du*u)
            end)
        elseif button == "wd" then
            if TWEEN then TIMER:cancel(TWEEN) end
            ZOOM = math.max(ZOOM / 2, 1 / 16)
            TWEEN = TIMER:tween(0.25, CAMERA, {scale = ZOOM}, "out-quad")
        end
    end
end

function love.mousereleased(x, y, button)
    local mx, my = CAMERA:worldCoords(x, y)
    mx, my = math.floor(mx), math.floor(my)
        
    MODE:mousereleased(mx, my, button)
end

function love.keypressed(key, isrepeat)
    if MODE:keypressed(key, isrepeat) then return end

    local function switch(mode)
        MODE:defocus()
        MODE = mode
        MODE:focus()
    end

    if PROJECT then
        local modes = {
            q = PROJECT.tilelayer.modes.pixel,
            a = PROJECT.tilelayer.modes.tile,

            w = PROJECT.entitylayer.modes.pixel,
            s = PROJECT.entitylayer.modes.place,

            e = PROJECT.tilelayer.modes.walls,

            r = PROJECT.notelayer.modes.annotate,
        } 

        if modes[key] then
            if love.keyboard.isDown("tab") then
                modes[key].layer.active = not modes[key].layer.active
            else
                switch(modes[key])
                modes[key].layer.active = true
            end
        end

        if key == "f11" and not isrepeat then
            love.window.setFullscreen(not FULL, "desktop")
            FULL = not FULL
        elseif key == "f12" and not isrepeat then
            PROJECT:save(PROJECT.name)
            love.system.openURL("file://"..love.filesystem.getSaveDirectory())
        elseif key == "z" and love.keyboard.isDown("lctrl") then
            PROJECT.tilelayer.tileset:undo()
        end

        if dirs[key] then
            local vx, vy = unpack(dirs[key])
            CAMERA:move(vx * 32, vy * 32)
        end
    end
end

function love.keyreleased(key)
    MODE:keyreleased(key)
end

function love.textinput(character)
    MODE:textinput(character)
end

local Camera = require "hump.camera"
local Timer = require "hump.timer"
local Palette = require "palette"
local Project = require "project"

local colour = require "colour"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.filesystem.mount(".", "projects")
    love.keyboard.setKeyRepeat(true)

    PALETTE = Palette.generate(3)
    TILE = 1
    FULL = false
    BRUSHSIZE = 1
    CAMERA = Camera(128, 128, 2)
    PROJECTP = "kooltooltestproject"

    if love.filesystem.exists(PROJECTP) then
        PROJECT = Project()
        PROJECT:load(PROJECTP)
    else
        PROJECT = Project.default()
    end

    MODE = PROJECT.tilelayer.modes.pixel

    TILESOUND = love.audio.newSource("sounds/marker pen.wav")
    TIMER = Timer()
    ZOOM = 2
end

function love.update(dt)
    TIMER:update(dt)
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

function love.draw()
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

    if button == "l" and MODE == PROJECT.tilelayer.modes.tile then
        local index = PROJECT.tilelayer.tileset:click(x, y)
        if index then TILE = index return true end
    end

    if MODE:mousepressed(mx, my, button) then return end

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

    local modes = {
        q = PROJECT.tilelayer.modes.pixel,
        w = PROJECT.tilelayer.modes.tile,
        e = PROJECT.notelayer.modes.annotate,
        r = PROJECT.tilelayer.modes.walls,
        --a = PROJECT.entitylayer.modes.pixel,
    }

    if modes[key] then switch(modes[key]) end

    if key == "f11" and not isrepeat then
        love.window.setFullscreen(not FULL, "desktop")
        FULL = not FULL
    end

    if key == "f12" and not isrepeat then
        PROJECT:save(PROJECTP)
        love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    elseif key == "z" and love.keyboard.isDown("lctrl") then
        PROJECT.tileset:undo()
    end

    if dirs[key] then
        local vx, vy = unpack(dirs[key])
        CAMERA:move(vx * 32, vy * 32)
    end
end

function love.keyreleased(key)
    MODE:keyreleased(key)
end

function love.textinput(character)
    MODE:textinput(character)
end

function draw_project_list()
    local projects = {}

    local items = love.filesystem.getDirectoryItems("projects", function(filename)
        if love.filesystem.isDirectory(filename) then
            projects[#projects+1] = filename
        end
    end)

    local list = table.concat(projects, "\n")

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf(list, 1, 4, 512)
end

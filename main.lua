if jit then require "imagedata-ffi" end

love.graphics.setDefaultFilter("nearest", "nearest")

if not love.graphics.isSupported("canvas") then
    --function love.load() image = love.graphics.newImage("images/nocanvas.png") end
    --function love.update(dt) end
    --function love.draw() love.graphics.draw(image, 0, 0) end
    --do return end

    local broken = love.graphics.newImage("images/broken.png")
    local common = require "common"
    love.graphics.newCanvas = function(w, h)
        return {
            fakecanvas=true,
            image=broken,
            renderTo=function()end,
            getDimensions=function() return w, h end,
        }
    end
    common.canvasFromImage = function(image)
        return {
            fakecanvas=true,
            image=image.fakecanvas and image.image or image,
            renderTo=function()end,
            getDimensions=function() return image:getDimensions() end,
        }
    end
    common.resizeCanvas = function(image, w, h)
        return {
            fakecanvas=true,
            image=image.fakecanvas and image.image or image,
            renderTo=function()end,
            getDimensions=function() return image:getDimensions() end,
        } 
    end

    local draw = love.graphics.draw
    love.graphics.draw = function(image, ...)
        if not image.fakecanvas then
            draw(image, ...)
        else
            draw(image.image, ...)
        end
    end

    local newSB = love.graphics.newSpriteBatch
    love.graphics.newSpriteBatch = function(texture, ...)
        if not texture.fakecanvas then
            return newSB(texture, ...)
        else
            return newSB(texture.image, ...)
        end
    end

    NOCANVAS = true
end

local Camera = require "hump.camera"
local Timer = require "hump.timer"
local Interface = require "interface"
local Palette = require "palette"
local Project = require "project"
local EditMode = require "editmode"

local TileLayer = require "tilelayer"
local NoteLayer = require "notelayer"
local NoteBox = require "notebox"

local Player = require "player"

local colour = require "colour"
local probe = require "probe"
local export = require "export"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    --love.filesystem.mount("projects", "saved_projects")
    love.keyboard.setKeyRepeat(true)

    PALETTE = Palette.generate(3)
    TILE = 1
    FULL = false
    BRUSHSIZE = 1
    CAMERA = Camera(128, 128, 2)

    TILESOUND = love.audio.newSource("sounds/marker pen.wav")
    TIMER = Timer()
    ZOOM = 2

    GPROFILER = probe.new()
    --GPROFILER:hookAll(_G, "draw", {love})
    --GPROFILER:hook(TileLayer, "draw", "TileLayer")
    --GPROFILER:hook(NoteLayer, "draw", "NoteLayer")
    --GPROFILER:hook(NoteBox, "draw", "NoteBox")
    CPROFILER = probe.new()
    --CPROFILER:hookAll(_G, "update", {love})

    if love.filesystem.isDirectory("embedded") then
        INTERFACE = Interface({})
        SETPROJECT(Project("embedded"))

        local players = {}

        for entity in pairs(PROJECT.entitylayer.entities) do
            local player = Player(entity, PROJECT.tilelayer.walls)
            players[player] = true
            PLAYER = player
            player.speed = 0.75
        end

        if PLAYER then PLAYER.speed = 0.25 end

        function love.update(dt)
            for player in pairs(players) do
                player:update(dt)

                if player ~= PLAYER then
                    player:rando()
                end
            end

            if PLAYER then
                CAMERA.x, CAMERA.y = PLAYER.entity.x, PLAYER.entity.y
            end
        end

        function love.draw() 
            CAMERA:attach()
            PROJECT:draw()
            CAMERA:detach()
        end

        function love.mousepressed(x, y, button)
        end

        function love.mousereleased(x, y, button)
        end

        function love.keypressed(key, isrepeat)
            if PLAYER then PLAYER:keypressed(key) end
        end

        function love.keyreleased(key)
        end

        function love.textinput(character)
        end

        return
    end

    local projects = {}

    local proj_path = "projects"

    local items = love.filesystem.getDirectoryItems(proj_path, function(filename)
        local path = proj_path .. "/" .. filename

        if love.filesystem.isDirectory(path) then
            local project = Project(path)
            project:loadIcon(path)

            projects[#projects+1] = project
        end
    end)

    local tutorial = Project("tutorial")
    tutorial:loadIcon("tutorial")
    table.insert(projects, 1, tutorial)

    INTERFACE = Interface(projects)
    MODE = INTERFACE.modes.select_project

    --love.filesystem.createDirectory("export_test", "kooltooltestproject1")
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

    MODE = PROJECT.tilelayer.modes.pixel
    INTERFACE.draw = function() end
end

local dirs = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function love.update(dt)
    CPROFILER:startCycle()

    --require("lovebird").update()

    TIMER:update(dt)
    
    if PROJECT then
        PROJECT:update(dt)
        MODE:update(dt)

        local mx, my = CAMERA:mousepos()
        mx, my = math.floor(mx), math.floor(my)

        MODE:hover(mx, my, dt)

        if DRAG then
            local mx, my = love.mouse.getPosition()
            local x, y, cx, cy = unpack(DRAG)

            local dx, dy = mx - x, my - y
            local s = CAMERA.scale

            CAMERA:lookAt(cx - dx / s, cy - dy / s)
        end
    end

    if not love.keyboard.isDown("lshift") then
        for key, vector in pairs(dirs) do
            if love.keyboard.isDown(key) then
                local vx, vy = unpack(vector)
                local speed = 256 / CAMERA.scale
                CAMERA:move(vx * speed * dt, vy * speed * dt)
            end
        end
    else
        if love.keyboard.isDown("down") then
            CAMERA.scale = CAMERA.scale - CAMERA.scale * dt
        elseif love.keyboard.isDown("up") then
            CAMERA.scale = CAMERA.scale + CAMERA.scale * dt
        end
    end

    CPROFILER:endCycle()
end

local large = love.graphics.newFont("fonts/PressStart2P.ttf", 8)

function love.draw()
    GPROFILER:startCycle()

    if PROJECT then
        CAMERA:attach()

        PROJECT.tilelayer:draw()

        local mx, my = CAMERA:mousepos()
        love.graphics.setColor(colour.random())

        love.graphics.push()
        love.graphics.scale(0.5)
        PROJECT.notelayer:draw()
        love.graphics.pop()

        PROJECT.entitylayer:draw()

        MODE:draw(mx, my)

        CAMERA:detach()

        PROJECT.tilelayer.tileset:draw()
        love.graphics.print(MODE.name, 3, 5)

        INTERFACE:draw()
    else
        INTERFACE:draw()
        MODE:draw()
    end

    if NOCANVAS then
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("fill", 0, 17, 512, 19)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.setFont(large)
        love.graphics.print("ERROR: cannot edit due to lack of OpenGL framebuffer support", 1, 4+16)
        love.graphics.print("       please report to ragzouken@gmail.com or tweet @ragzouken", 1, 4+16+9)
    end

    GPROFILER:endCycle()
    love.graphics.setColor(colour.random(128, 255))
    --GPROFILER:draw(16, 16, 192, 512-32, "DRAW CYCLE")
    --CPROFILER:draw(512-16-192, 16, 192, 512-32, "UPDATE CYCLE")
end

function zoom_on(mx, my)
    DRAG = nil
    if TWEEN then TIMER:cancel(TWEEN) end
    ZOOM = math.min(ZOOM * 2, 16)
    
    local dx, dy, dz = CAMERA.x - mx, CAMERA.y - my, ZOOM - CAMERA.scale
    local oscale = CAMERA.scale
    local factor = ZOOM / CAMERA.scale
    local t = 0

    TWEEN = TIMER:do_for(0.25, function(dt)
        t = t + dt
        local u = t / 0.25
        local du = factor - 1

        CAMERA.scale = oscale*factor - (1 - u) * dz
        CAMERA.x, CAMERA.y = mx + dx / (1 + du*u), my + dy / (1 + du*u)
    end)
end

function zoom_out()
    DRAG = nil
    if TWEEN then TIMER:cancel(TWEEN) end
    ZOOM = math.max(ZOOM / 2, 1 / 16)
    TWEEN = TIMER:tween(0.25, CAMERA, {scale = ZOOM}, "out-quad")
end

function love.mousepressed(x, y, button)
    local mx, my = CAMERA:worldCoords(x, y)
    mx, my = math.floor(mx), math.floor(my)

    local w, h = love.window.getDimensions()
    if x <= 0 or y <= 0 or x >= w or y >= w then return end

    if PROJECT and not love.keyboard.isDown("tab") then
        if button == "l" and MODE == PROJECT.tilelayer.modes.tile then
            local index = PROJECT.tilelayer.tileset:click(x, y)
            if index then TILE = index return true end
        end
    end

    if not love.keyboard.isDown("tab") then
        if MODE:mousepressed(mx, my, button) then return end
    end

    if PROJECT then
        if button == "m" then
            DRAG = {x, y, CAMERA.x, CAMERA.y}
        elseif button == "wu" or (love.keyboard.isDown("tab") and button == "l") then
            zoom_on(mx, my)
        elseif button == "wd" or (love.keyboard.isDown("tab") and button == "r") then
            zoom_out()
        end
    end
end

function love.mousereleased(x, y, button)
    if PROJECT then
        if button == "m" and not DRAG[5] then DRAG = nil end

        local mx, my = CAMERA:worldCoords(x, y)
        mx, my = math.floor(mx), math.floor(my)
            
        MODE:mousereleased(mx, my, button)
    end
end

function love.keypressed(key, isrepeat)
    if key == "tab" and not isrepeat then
        local x, y = love.mouse.getPosition()
        DRAG = {x, y, CAMERA.x, CAMERA.y, "tab"}
        return
    end
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

        if key == "f10" and not isrepeat then
            --local w, h, flags = love.window.getMode()
            --flags.vsync = not flags.vsync
            --love.window.setMode(w, h, flags)
        elseif key == "f11" and not isrepeat then
            love.window.setFullscreen(not FULL, "desktop")
            FULL = not FULL
        elseif (key == "f12" or (key == "s" and love.keyboard.isDown("lctrl"))) and not isrepeat then
            PROJECT:save("projects/" .. PROJECT.name)

            if love.keyboard.isDown("lshift") then
                PROJECT:export()
                love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/releases/" .. PROJECT.name)
            end
        elseif key == "z" and love.keyboard.isDown("lctrl") then
            PROJECT.tilelayer.tileset:undo()
        end
    end
end

function love.keyreleased(key)
    if key == "tab" and DRAG and DRAG[5] == "tab" then DRAG = nil return end

    MODE:keyreleased(key)
end

function love.textinput(character)
    MODE:textinput(character)
end

function love.focus()
end

local Timer = require "hump.timer"

local Project = require "project"
local Interface = require "interface"

local generators = require "generators"
local colour = require "colour"

local Pan = require "actions.pan"

function love.load()
    TILESOUND = love.audio.newSource("sounds/marker pen.wav")
    CLONESOUND = love.audio.newSource("sounds/clone.wav")
    SAVESOUND = love.audio.newSource("sounds/save.wav")
    TIMER = Timer()
    PALETTE = generators.Palette.generate(3)
    TILE = 1
    FULL = false
    BRUSHSIZE = 1

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

    INTERFACE = Interface(projects)
    MODE = INTERFACE.modes.select_project
    ACTION = nil
end

local dirs = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function love.update(dt)
    local sx, sy = love.mouse.getPosition()
    if ACTION then ACTION:update(dt, sx, sy, CAMERA:mousepos()) end

    TIMER:update(dt)

    if CAMERA.scale % 1 == 0 then CAMERA.x, CAMERA.y = math.floor(CAMERA.x), math.floor(CAMERA.y) end

    if PROJECT then
        PROJECT:update(dt)
        DRAGDELETEMODE:update(dt)
        MODE:update(dt)

        local mx, my = CAMERA:mousepos()
        mx, my = math.floor(mx), math.floor(my)

        if MODE ~= PIXELMODE and DRAGDELETEMODE:hover(mx, my, dt) then
        else MODE:hover(mx, my, dt) end
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
end

local medium = love.graphics.newFont("fonts/PressStart2P.ttf", 8)
local large = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

local pencil = love.graphics.newImage("images/pencil.png")
local tiles = love.graphics.newImage("images/tiles.png")
local marker = love.graphics.newImage("images/marker.png")
local entity = love.graphics.newImage("images/entity.png")
local note = love.graphics.newImage("images/note.png")
local save = love.graphics.newImage("images/save.png")
local export = love.graphics.newImage("images/export.png")

function love.draw()
    if PROJECT then
        CAMERA:attach()

        PROJECT:draw(true)

        local mx, my = CAMERA:mousepos()
        love.graphics.setColor(colour.random())
        MODE:draw(mx, my)

        CAMERA:detach()

        local o = 4-1+32+2
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", 0, 0, 512, 16 + 3)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setFont(large)
        love.graphics.print(" " .. MODE.name, 3+o, 5)

        PROJECT.layers.surface.tileset:draw()

        INTERFACE:draw()

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setBlendMode("premultiplied")
        love.graphics.rectangle("fill", 4-1, 4-1, 32+2, 8*(32+1)+1)

        love.graphics.setColor(PALETTE.colours[3])
        love.graphics.draw(pencil, 4, 4 + 0 * 33, 0, 1, 1)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.draw(tiles, 4, 4 + 1 * 33, 0, 1, 1)
        love.graphics.setColor(colour.cursor(0))
        love.graphics.draw(marker, 4, 4 + 2 * 33, 0, 1, 1)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.draw(entity, 4, 4 + 3 * 33, 0, 1, 1)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.draw(note, 4, 4 + 4 * 33, 0, 1, 1)
        love.graphics.draw(save, 4, 4 + 5 * 33, 0, 1, 1)
        love.graphics.draw(export, 4, 4 + 6 * 33, 0, 1, 1)
    else
        INTERFACE:draw()
        MODE:draw()
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
end

function zoom_on(mx, my)
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
    if TWEEN then TIMER:cancel(TWEEN) end
    ZOOM = math.max(ZOOM / 2, 1 / 16)
    TWEEN = TIMER:tween(0.25, CAMERA, {scale = ZOOM}, "out-quad")
end

function love.mousepressed(x, y, button)
    local wx, wy = CAMERA:worldCoords(x, y)
    if ACTION then ACTION:mousepressed(button, x, y, wx, wy) return end

    local mx, my = CAMERA:worldCoords(x, y)
    mx, my = math.floor(mx), math.floor(my)

    if x <= 35 then
        if y <= 36 then MODE = PIXELMODE return
        elseif y <= 70 then MODE = TILEMODE return
        elseif y <= 106 then MODE = ANNOTATEMODE return
        elseif y <= 125 then
            MODE = TILEMODE
            MODE.state.selected = PROJECT:newEntity(mx, my)
            DRAGDELETEMODE:mousepressed(mx, my, button)
            return
        elseif y <= 168 then
            MODE = ANNOTATEMODE
            MODE.state.selected = PROJECT:newNotebox(mx, my)
            DRAGDELETEMODE:mousepressed(mx, my, button)
            return
        elseif y <= 201 then
            SAVESOUND:play()
            PROJECT:save("projects/" .. PROJECT.name)
            love.system.openURL("file://"..love.filesystem.getSaveDirectory())
            return
        elseif y <= 234 then
            SAVESOUND:play()
            PROJECT:save("projects/" .. PROJECT.name)
            PROJECT:export()
            love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/releases/" .. PROJECT.name)
            return
        end
    end

    if PROJECT then
        if button == "wu" or (love.keyboard.isDown("tab") and button == "l") then
            zoom_on(mx, my)
        elseif button == "wd" or (love.keyboard.isDown("tab") and button == "r") then
            zoom_out()
        elseif button == "r" then
            ACTION = Pan(function() ACTION = nil end)
            ACTION:mousepressed(button, x, y, CAMERA:mousepos())
            return
        end
    end

    local w, h = love.window.getDimensions()
    if x <= 0 or y <= 0 or x >= w or y >= w then return end

    if PROJECT then
        if button == "l" then
            local index = PROJECT.layers.surface.tileset:click(x, y)
            if index then
                TILE = index 
                MODE = TILEMODE
                return true
            end
        end
    end

    if not love.keyboard.isDown("tab") then
        if PROJECT and MODE ~= PIXELMODE and DRAGDELETEMODE:mousepressed(mx, my, button) then return end
        if MODE:mousepressed(mx, my, button) then return end
    end
end

function love.mousereleased(x, y, button)
    local wx, wy = CAMERA:worldCoords(x, y)
    if ACTION then ACTION:mousereleased(button, x, y, wx, wy) return end

    if PROJECT then
        local mx, my = CAMERA:worldCoords(x, y)
        mx, my = math.floor(mx), math.floor(my)
        
        DRAGDELETEMODE:mousereleased(mx, my, button)
        MODE:mousereleased(mx, my, button)
    end
end

function love.keypressed(key, isrepeat)
    if DRAGDELETEMODE:keypressed(key, isrepeat) then return
    elseif MODE:keypressed(key, isrepeat) then return
    end

    local function switch(mode)
        MODE:defocus()
        MODE = mode
        MODE:focus()
    end

    if PROJECT then
        local modes = {
            q = PIXELMODE,
            w = TILEMODE,
            e = ANNOTATEMODE,
        } 

        if modes[key] then
            if love.keyboard.isDown("tab") then
                --modes[key].layer.active = not modes[key].layer.active
            else
                switch(modes[key])
            end
        end

        local mx, my = CAMERA:mousepos()
        mx, my = math.floor(mx), math.floor(my)

        if key == "t" then 
            PROJECT:newEntity(mx, my)
        elseif key == "y" then
            PROJECT:newNotebox(mx, my)
        elseif key == "f10" and not isrepeat then
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
            PROJECT:undo()
        end
    end
end

function love.keyreleased(key)
    MODE:keyreleased(key)
end

function love.textinput(character)
    if not DRAGDELETEMODE:textinput(character) then
        MODE:textinput(character)
    end
end

function love.focus(focus)
    if not focus then
        MODE:defocus()
    else
        MODE:focus()
    end
end

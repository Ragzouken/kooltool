local Timer = require "hump.timer"

local Project = require "project"
local InterfaceWrong = require "interfacewrong"
local Interface = require "interface"

local generators = require "generators"
local colour = require "colour"

function love.load()
    TIMER = Timer()
    PALETTE = generators.Palette.generate(3)
    SAVESOUND = love.audio.newSource("sounds/save.wav")
    FULL = false

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

    POO = InterfaceWrong(projects)
    INTERFACE = POO.modes.select_project
    ACTION = nil
end

local dirs = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function love.update(dt)
    if PROJECT and not INTERFACE_ then 
        INTERFACE_ = Interface(PROJECT)
    end

    local sx, sy = love.mouse.getPosition()
    local wx, wy = CAMERA:mousepos()

    if INTERFACE_ then INTERFACE_:update(dt, sx, sy, wx, wy) end

    TIMER:update(dt)

    colour.walls(dt, 0)

    if CAMERA.scale % 1 == 0 then CAMERA.x, CAMERA.y = math.floor(CAMERA.x), math.floor(CAMERA.y) end

    if PROJECT then
        PROJECT:update(dt)
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
local walls = love.graphics.newImage("images/walls.png")
local marker = love.graphics.newImage("images/marker.png")
local entity = love.graphics.newImage("images/entity.png")
local note = love.graphics.newImage("images/note.png")
local save = love.graphics.newImage("images/save.png")
local export = love.graphics.newImage("images/export.png")

function love.draw()
    if PROJECT then
        CAMERA:attach()

        PROJECT:draw(true)
        
        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()
        INTERFACE_:cursor(sx, sy, wx, wy)

        CAMERA:detach()

        if INTERFACE_.active then
            local o = 4-1+32+2
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(0, 0, 0, 255)
            love.graphics.rectangle("fill", 0, 0, 512, 16 + 3)
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.setFont(large)
            love.graphics.print(" " .. INTERFACE_.active.name, 3+o, 5)
        end

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
        love.graphics.draw(walls, 4, 4 + 7 * 33, 0, 1, 1)
    else
        INTERFACE:draw()
        POO:draw()
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

function love.mousepressed(x, y, button)
    local wx, wy = CAMERA:worldCoords(x, y)

    if PROJECT then
        if x <= 35 then
            if y <= 36 then
                INTERFACE_.active = INTERFACE_.tools.draw
                return
            elseif y <= 70 then
                INTERFACE_.active = INTERFACE_.tools.tile
                return
            elseif y <= 106 then
                INTERFACE_.active = INTERFACE_.tools.marker
                return
            elseif y <= 125 then
                local entity = PROJECT:newEntity(wx, wy)
                INTERFACE_.action = INTERFACE_.tools.drag
                INTERFACE_.action:grab(entity, x, y, wx, wy)
                return
            elseif y <= 168 then
                local notebox = PROJECT:newNotebox(wx, wy)
                INTERFACE_.action = INTERFACE_.tools.drag
                INTERFACE_.action:grab(notebox, x, y, wx, wy)
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
            elseif y <= 267 then
                INTERFACE_.active = INTERFACE_.tools.wall
                return
            end
        end

        if button == "l" then
            local index = PROJECT.layers.surface.tileset:click(x, y)
            if index then
                INTERFACE_.active = INTERFACE_.tools.tile
                INTERFACE_.active.tile = index
                return true
            end
        end

        if INTERFACE_:input("mousepressed", button, x, y, wx, wy) then
            return
        end
    else
        INTERFACE:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)    
    if PROJECT then
        local wx, wy = CAMERA:worldCoords(x, y)

        INTERFACE_:input("mousereleased", button, x, y, wx, wy)
    end
end

function love.keypressed(key, isrepeat)
    if PROJECT then
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
            PROJECT.history:undo()
        end

        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()

        if not isrepeat then
            INTERFACE_:input("keypressed", key, sx, sy, wx, wy)
        end
    end
end

function love.keyreleased(key)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()

        INTERFACE_:input("keyreleased", key, sx, sy, wx, wy)
    end
end

function love.textinput(character)
    if PROJECT then
        local sx, sy = love.mouse.getPosition()
        local wx, wy = CAMERA:mousepos()

        INTERFACE_:input("textinput", character, sx, sy, wx, wy)
    end
end

function love.focus(focus)
end

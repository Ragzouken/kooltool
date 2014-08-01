local Camera = require "hump.camera"
local Palette = require "palette"
local Notebox = require "notebox"
local Project = require "project"

local json = require "json"
local bresenham = require "bresenham"
local colour = require "colour"
local brush = require "brush"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.filesystem.mount(".", "projects")
    love.keyboard.setKeyRepeat(true)

    PALETTE = Palette.generate(3)
    TOOL = "pixel"
    TILE = 1
    FULL = false
    BRUSHSIZE = 1
    CAMERA = Camera(128, 128, 2)
    PROJECTP = "projects/kooltooltestproject"

    if love.filesystem.exists(PROJECTP) then
        PROJECT = Project()
        PROJECT:load(PROJECTP)
    else
        PROJECT = Project.default()
    end
end

function love.update(dt)
    PROJECT:update(dt)

    if not love.keyboard.isDown("lshift") then LOCK = nil end

    if love.mouse.isDown("l") then
        local mx, my = love.mouse.getPosition()
        local gx, gy, tx, ty = PROJECT.tilelayer:gridCoords(CAMERA:mousepos())

        local index = PROJECT.tileset:click(mx, my)

        if index then
            TILE = index
        elseif TOOL == "pixel" then
            if love.keyboard.isDown("lalt") then
                PALETTE.colours[3] = PROJECT.tilelayer:sample(CAMERA:mousepos())
            else
                local mx, my = CAMERA:mousepos()
                mx, my = math.floor(mx), math.floor(my)

                local x1, y1, x2, y2 = mx, my, mx, my
                if lastdraw then x2, y2 = unpack(lastdraw) end

                local brush, ox, oy = brush.line(x1, y1, x2, y2, BRUSHSIZE, PALETTE.colours[3])
                PROJECT.tilelayer:applyBrush(ox, oy, brush, LOCK, lastclone)

                lastdraw = {mx, my}
            end
        elseif TOOL == "tile" then
            if love.keyboard.isDown("lalt") then
                TILE = PROJECT.tilelayer:get(gx, gy) or TILE
            else
                PROJECT.tilelayer:set(TILE, gx, gy)
            end
        end

        nextclone = nil
    else
        lastdraw = nil
    end

    if love.mouse.isDown("m") and DRAG then
        local mx, my = love.mouse.getPosition()
        local x, y, cx, cy = unpack(DRAG)

        local dx, dy = mx - x, my - y
        local s = CAMERA.scale

        CAMERA:lookAt(cx - dx / s, cy - dy / s)
    end

    love.window.setTitle(love.timer.getFPS())
end

function love.draw()
    --VIEW:draw()

    CAMERA:attach()

    PROJECT.tilelayer:draw()

    local mx, my = CAMERA:mousepos()
    love.graphics.setColor(colour.random())

    if TOOL == "pixel" then     
        PROJECT.tilelayer:drawBrushCursor(mx, my, BRUSHSIZE, PALETTE.colours[3], LOCK)
    elseif TOOL == "tile" then
        PROJECT.tilelayer:drawTileCursor(mx, my)
    end

    love.graphics.push()
    love.graphics.scale(0.5)
    PROJECT.notelayer:draw()
    love.graphics.pop()

    CAMERA:detach()

    PROJECT.tileset:draw()
    love.graphics.print(TOOL, 3, 5)
end

local dirs = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function love.mousepressed(x, y, button)
    if TOOL == "note" then
        local mx, my = CAMERA:worldCoords(x, y)
        PROJECT.notelayer:mousepressed(mx*2, my*2, button)
    end

    if button == "l" and TOOL == "pixel" then
        PROJECT.tileset:snapshot(3)
    elseif button == "m" then
        DRAG = {x, y, CAMERA.x, CAMERA.y}
    elseif button == "wu" then
        CAMERA.scale = CAMERA.scale * 2
    elseif button == "wd" then
        CAMERA.scale = CAMERA.scale / 2
    end
end

function love.mousereleased(x, y, button)
    if TOOL == "note" then
        local mx, my = CAMERA:worldCoords(x, y)
        PROJECT.notelayer:mousereleased(mx*2, my*2, button)
    end
end

function love.keypressed(key, isrepeat)
    if key == "escape" then TOOL = "pixel" end
    if TOOL == "note" then 
        PROJECT.notelayer:keypressed(key)
        return
    end

    if key == " " then
        PALETTE = Palette.generate(5)
    elseif key == "lctrl" and not isrepeat then
        nextclone = true
    end

    if key == "q" then TOOL = "pixel" end
    if key == "w" then TOOL = "tile" end
    if key == "e" then TOOL = "note" end
    if key == "1" then BRUSHSIZE = 1 end
    if key == "2" then BRUSHSIZE = 2 end
    if key == "3" then BRUSHSIZE = 3 end

    if key == "f11" and not isrepeat then
        love.window.setFullscreen(not FULL, "desktop")
        FULL = not FULL
    end

    if key == "s" and not isrepeat then
        PROJECT:save(PROJECTP)
        love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    elseif key == "z" and love.keyboard.isDown("lctrl") then
        PROJECT.tileset:undo()
    end

    if key == "lshift" and not isrepeat then
        LOCK = {PROJECT.tilelayer:gridCoords(CAMERA:mousepos())}
    end

    if dirs[key] then
        local vx, vy = unpack(dirs[key])
        CAMERA:move(vx * 32, vy * 32)
    end
end

function love.keyreleased(key)
    if key == "lctrl" then nextclone = nil end
end

function love.textinput(character)
    if TOOL == "note" then PROJECT.notelayer:textinput(character) end
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

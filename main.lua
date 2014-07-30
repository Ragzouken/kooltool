local Palette = require "palette"
local Tileset = require "tileset"
local TileMap = require "tilemap"
local TileMapView = require "tilemapview"
local Notebox = require "notebox"

local bresenham = require "bresenham"

FONT = love.graphics.newFont("fonts/PressStart2P.ttf", 16)
love.graphics.setFont(FONT)

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.filesystem.mount(".", "projects")

    tileset = Tileset()

    PALETTE = Palette.generate(3)

    tileset:renderTo(tileset:add_tile(), function()
        love.graphics.setColor(PALETTE.colours[1])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end)

    tileset:renderTo(tileset:add_tile(), function()
        love.graphics.setColor(PALETTE.colours[2])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end)

    TOOL = "pixel"
    TILE = 1
    FULL = false
    BRUSHSIZE = 1

    --love.mouse.setVisible(false)

    if love.filesystem.exists("projects/kooltooltestproject") then
        local tiles = love.graphics.newImage("projects/kooltooltestproject/tileset.png")
        tileset.canvas:renderTo(function()
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.draw(tiles, 0, 0)
        end)

        tilemap = TileMap.load(love.filesystem.read("projects/kooltooltestproject/map1.txt"))
    else
        tilemap = TileMap(tileset)

        for y=0,7 do
            for x=0,7 do
                tilemap:set(love.math.random(2), x, y)
            end
        end
    end

    TEXT = "test"

    VIEW = TileMapView(tilemap)
    BOX = Notebox(100, 100, [[this is a particularly
difficut section of the
game]])

    love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
    if not love.keyboard.isDown("lshift") then LOCK = nil end

    if love.mouse.isDown("l") then
        local mx, my = love.mouse.getPosition()
        local gx, gy, tx, ty = VIEW:grid_coords(VIEW.camera:mousepos())

        local index = tileset:click(mx, my)

        if index then
            TILE = index
        elseif TOOL == "pixel" then
            if love.keyboard.isDown("lalt") then
                PALETTE.colours[3] = VIEW:sample(VIEW.camera:mousepos())
            else
                local mx, my = VIEW.camera:mousepos()
                mx, my = math.floor(mx), math.floor(my)

                local x1, y1, x2, y2 = mx, my, mx, my
                if lastdraw then x2, y2 = unpack(lastdraw) end

                draw_line(x1, y1, x2, y2, BRUSHSIZE)

                lastdraw = {mx, my}
            end
        elseif TOOL == "tile" then
            if love.keyboard.isDown("lalt") then
                TILE = tilemap:get(gx, gy) or TILE
            else
                tilemap:set(TILE, gx, gy)
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
        local s = VIEW.camera.scale

        VIEW.camera:lookAt(cx - dx / s, cy - dy / s)
    end

    love.window.setTitle(love.timer.getFPS())
end

function love.draw()
    --tilemap:draw()

    VIEW:draw()

    VIEW.camera:attach()
    love.graphics.push()
    love.graphics.scale(0.5)
    BOX:draw()
    love.graphics.pop()
    VIEW.camera:detach()

    local mx, my = love.mouse.getPosition()
    local gx, gy, tx, ty = VIEW:grid_coords(VIEW.camera:mousepos())

    local function rando()
        return 128 + love.math.random() * 128, 128 + love.math.random() * 128, 128 + love.math.random() * 128, 255
    end

    if TOOL == "pixel" then
        local size = BRUSHSIZE
        local le = math.floor(size / 2)

        VIEW.camera:draw(function()
            local x, y = VIEW.camera:worldCoords(mx, my)

            love.graphics.setColor(rando())
            --love.graphics.rectangle("fill", math.floor(x)-8, math.floor(y)-le, 16, size)
            --love.graphics.rectangle("fill", math.floor(x)-le, math.floor(y)-8, size, 16)
            love.graphics.setColor(PALETTE.colours[3])
            love.graphics.rectangle("fill", math.floor(x)-le, math.floor(y)-le, size, size)
        end)

        if LOCK then
            local gx, gy = unpack(LOCK)
            love.graphics.setColor(rando())
            VIEW:draw_tile_border(gx, gy)
        end
    elseif TOOL == "tile" then
        local x, y = VIEW:pixel_coords(gx, gy)

        love.graphics.setColor(rando())
        VIEW:draw_tile_border(gx, gy)

        love.graphics.setColor(255, 255, 255, 128)
        VIEW:draw_tile_cursor(gx, gy, TILE)
    end

    tileset:draw()

    love.graphics.print(TOOL, 3, 5)
end

local dirs = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function love.mousepressed(x, y, button)
    if button == "l" and TOOL == "pixel" then
        tileset:snapshot(3)
    elseif button == "m" then
        DRAG = {x, y, VIEW.camera.x, VIEW.camera.y}
    elseif button == "wu" then
        VIEW.camera.scale = VIEW.camera.scale * 2
    elseif button == "wd" then
        VIEW.camera.scale = VIEW.camera.scale / 2
    end
end

function love.keypressed(key, isrepeat)
    if key == "escape" then TOOL = "pixel" end
    if TOOL == "note" then 
        BOX:keypressed(key)
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
        love.filesystem.createDirectory("kooltooltestproject")
        local file = love.filesystem.newFile("kooltooltestproject/map1.txt", "w")
        file:write(tilemap:serialise())
        file:close()
        
        local data = tileset.canvas:getImageData()
        data:encode("kooltooltestproject/tileset.png")

        love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    elseif key == "z" and love.keyboard.isDown("lctrl") then
        tileset:undo()
    end

    if key == "lshift" then
        LOCK = {VIEW:grid_coords(VIEW.camera:mousepos())}
    end

    if dirs[key] then
        local vx, vy = unpack(dirs[key])
        VIEW.camera:move(vx * 32, vy * 32)
    end
end

function love.keyreleased(key)
    if key == "lctrl" then nextclone = nil end
end

function love.textinput(character)
    if TOOL == "note" then BOX:textinput(character) end
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

function draw_line(x1, y1, x2, y2, size)
    local le = math.floor(size / 2)
    local re = size - le

    local w, h = math.abs(x2 - x1), math.abs(y2 - y1)
    local x, y = math.min(x1, x2), math.min(y1, y2)

    local brush = love.graphics.newCanvas(w+2+1+size, h+2+1+size)

    brush:renderTo(function()
        love.graphics.push()
        love.graphics.translate(1-x, 1-y)

        love.graphics.setColor(PALETTE.colours[3])
        local sx, sy = x1+le, y1+le
        local ex, ey = x2+le, y2+le

        for x, y in bresenham.line(sx, sy, ex, ey) do
            love.graphics.rectangle("fill", x - le, y - le, size, size)
        end

        love.graphics.pop()
    end)

    VIEW:apply_brush(x-1-le, y-1-le, brush, LOCK, nextclone)
end

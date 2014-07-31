local Camera = require "hump.camera"
local Palette = require "palette"
local Tileset = require "tileset"
local TileLayer = require "tilelayer"
local NoteLayer = require "notelayer"
local Notebox = require "notebox"

local json = require "json"
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

    PROJECT = "projects/kooltooltestproject"

    if love.filesystem.exists(PROJECT) then
        local tiles = love.graphics.newImage(PROJECT .. "/tileset.png")
        tileset.canvas:renderTo(function()
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.draw(tiles, 0, 0)
        end)

        local data = love.filesystem.read(PROJECT .. "/tilelayer.json")
        tilelayer = TileLayer(tileset)
        tilelayer:deserialise(json.decode(data))

        local data = love.filesystem.read(PROJECT .. "/notelayer.json")
        notelayer = NoteLayer()
        notelayer:deserialise(json.decode(data))
    else
        tilelayer = TileLayer(tileset)
        notelayer = NoteLayer()

        for y=0,7 do
            for x=0,7 do
                tilelayer:set(love.math.random(2), x, y)
            end
        end

        local defaultnotes = {
[[
welcome to kooltool
please have fun]],
[[
in pixel mode (q) draw you can 
create a set of beautiful tiles
as building blocks for a world]],
[[
in tile mode (w) you can build your
own landscape from your tiles]],
[[
in note mode (e) you can keep notes
on your project for planning and
commentary (escape to leave mode)]],
[[
press alt to copy the tile or
colour currently under the mouse]],
[[
you can drag notes
around in note mode]],
[[
you can delete notes with
right click in note mode]],
[[
hold the middle click and drag
to move around the world]],
[[
use the mouse wheel
to zoom in and out]],
[[
press s to save]],
        }

        for i, note in ipairs(defaultnotes) do
            local x = love.math.random(256-128, 512-128)
            local y = (i - 1) * (512 / #defaultnotes) + 32
            notelayer:addNotebox(Notebox(notelayer, x, y, note))
        end
    end

    TEXT = "test"

    CAMERA = Camera(128, 128, 2)

    love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
    notelayer:update(dt)

    if not love.keyboard.isDown("lshift") then LOCK = nil end

    if love.mouse.isDown("l") then
        local mx, my = love.mouse.getPosition()
        local gx, gy, tx, ty = tilelayer:gridCoords(CAMERA:mousepos())

        local index = tileset:click(mx, my)

        if index then
            TILE = index
        elseif TOOL == "pixel" then
            if love.keyboard.isDown("lalt") then
                PALETTE.colours[3] = tilelayer:sample(CAMERA:mousepos())
            else
                local mx, my = CAMERA:mousepos()
                mx, my = math.floor(mx), math.floor(my)

                local x1, y1, x2, y2 = mx, my, mx, my
                if lastdraw then x2, y2 = unpack(lastdraw) end

                draw_line(x1, y1, x2, y2, BRUSHSIZE)

                lastdraw = {mx, my}
            end
        elseif TOOL == "tile" then
            if love.keyboard.isDown("lalt") then
                TILE = tilelayer:get(gx, gy) or TILE
            else
                tilelayer:set(TILE, gx, gy)
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

    tilelayer:draw()

    local function rando()
        return 128 + love.math.random() * 128, 128 + love.math.random() * 128, 128 + love.math.random() * 128, 255
    end

    local mx, my = CAMERA:mousepos()
    love.graphics.setColor(rando())

    if TOOL == "pixel" then     
        tilelayer:drawBrushCursor(mx, my, BRUSHSIZE, PALETTE.colours[3], LOCK)
    elseif TOOL == "tile" then
        tilelayer:drawTileCursor(mx, my)
    end

    love.graphics.push()
    love.graphics.scale(0.5)
    notelayer:draw()
    love.graphics.pop()

    CAMERA:detach()

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
    if TOOL == "note" then
        local mx, my = CAMERA:worldCoords(x, y)
        notelayer:mousepressed(mx*2, my*2, button)
    end

    if button == "l" and TOOL == "pixel" then
        tileset:snapshot(3)
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
        notelayer:mousereleased(mx*2, my*2, button)
    end
end

function love.keypressed(key, isrepeat)
    if key == "escape" then TOOL = "pixel" end
    if TOOL == "note" then 
        notelayer:keypressed(key)
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
        local file = love.filesystem.newFile("kooltooltestproject/tilelayer.json", "w")
        file:write(json.encode(tilelayer:serialise()))
        file:close()
        
        local file = love.filesystem.newFile("kooltooltestproject/notelayer.json", "w")
        file:write(json.encode(notelayer:serialise()))
        file:close()

        local data = tileset.canvas:getImageData()
        data:encode("kooltooltestproject/tileset.png")

        love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    elseif key == "z" and love.keyboard.isDown("lctrl") then
        tileset:undo()
    end

    if key == "lshift" and not isrepeat then
        LOCK = {tilelayer:gridCoords(CAMERA:mousepos())}
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
    if TOOL == "note" then notelayer:textinput(character) end
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

    tilelayer:applyBrush(x-1-le, y-1-le, brush, LOCK, nextclone)
end

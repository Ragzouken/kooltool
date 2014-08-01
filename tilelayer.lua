local Class = require "hump.class"
local SparseGrid = require "sparsegrid"
local Tileset = require "tileset"

local brush = require "brush"
local colour = require "colour"

local TileLayer = Class {}

function TileLayer.default()
    local layer = TileLayer()

    layer.tileset = Tileset()

    layer.tileset:renderTo(layer.tileset:add_tile(), function()
        love.graphics.setColor(PALETTE.colours[1])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end)

    layer.tileset:renderTo(layer.tileset:add_tile(), function()
        love.graphics.setColor(PALETTE.colours[2])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end)

    for y=0,7 do
        for x=0,7 do
            layer:set(love.math.random(2), x, y)
        end
    end

    return layer
end

function TileLayer:deserialise(data, saves)
    self.tileset = Tileset()
    self.tileset:deserialise(data.tileset, saves)

    for y, row in pairs(data.tiles) do
        for x, index in pairs(row) do
            if index > 0 then self:set(index, tonumber(x), tonumber(y)) end
        end
    end
end

function TileLayer:serialise(saves)
    local tiles = {}

    for tile, x, y in self.tiles:items() do
        tiles[y] = tiles[y] or {}
        tiles[y][x] = tile[1]
    end

    return {
        tileset = self.tileset:serialise(saves),
        tiles = tiles,
    }
end

function TileLayer:init()
    self.tileset = Tileset()
    self.batch = love.graphics.newSpriteBatch(love.graphics.newCanvas(32, 32))

    self.tiles = SparseGrid(32)

    self.input_state = {}
end

function TileLayer:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)
    
    self.batch:setTexture(self.tileset.canvas)
    love.graphics.draw(self.batch, 0, 0)

    if self.input_state.lock then
        love.graphics.setColor(colour.random(128, 255))

        local tsize = 32
        local lx, ly = unpack(self.input_state.lock)
        love.graphics.rectangle("line", lx*tsize-0.5, ly*tsize-0.5, tsize+1, tsize+1)
    end
end

function TileLayer:drawBrushCursor(x, y, size, colour)
    local gx, gy, ox, oy = self:gridCoords(x, y)
    local tsize = 32

    local le = math.floor(size / 2)

    love.graphics.setColor(colour)
    love.graphics.rectangle("fill", math.floor(x)-le, math.floor(y)-le, size, size)
end

function TileLayer:drawTileCursor(x, y, index)
    local gx, gy, ox, oy = self:gridCoords(x, y)
    local size = 32

    local quad = self.tileset.quads[TILE]

    love.graphics.rectangle("line", gx*size-0.5, gy*size-0.5, size+1, size+1)
    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.draw(self.tileset.canvas, quad, gx * size, gy * size)
end

function TileLayer:get(gx, gy)
    local tile = self.tiles:get(gx, gy)

    return tile and tile[1] or nil
end

function TileLayer:set(index, gx, gy)
    local quad = self.tileset.quads[index]
    local existing = self.tiles:get(gx, gy)
    local id = existing and existing[2]

    local size = 32

    if id then
        self.batch:set(id, quad, gx * size, gy * size)
    else
        id = self.batch:add(quad, gx * size, gy * size)
    end

    self.tiles:set({index, id}, gx, gy)
end

function TileLayer:gridCoords(x, y)
    return self.tiles:gridCoords(x, y)
end

function TileLayer:applyBrush(bx, by, brush, lock)
    local gx, gy, tx, ty = self:gridCoords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile TODO: (if unlocked)
    local bw, bh = brush:getDimensions()
    local size = 32

    local gw, gh = math.ceil((bw + tx) / size), math.ceil((bh + ty) / size)
    local quad = love.graphics.newQuad(0, 0, size, size, bw, bh)

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local index = self:get(gx + x, gy + y)
            quad:setViewport(-tx + x * size, -ty + y * size, size, size)

            local locked = lock and (lock[1] ~= x+gx or lock[2] ~= y+gy)
            local key = tostring(gx + x) .. "," .. tostring(gy + y)

            if self.input_state.cloning and not self.input_state.cloning[key] then
                index = self.tileset:clone(index)
                self:set(index, gx + x, gy + y)
                self.input_state.cloning[key] = true
            end

            if index and not locked then
                self.tileset:renderTo(index, function()
                    love.graphics.draw(brush, quad, 0, 0)
                end)
            end
        end
    end
end

function TileLayer:sample(x, y)
    local gx, gy, ox, oy = self:gridCoords(x, y)
    local index = self:get(gx, gy)

    return index and self.tileset:sample(index, ox, oy) or {0, 0, 0, 255}
end

function TileLayer:update(dt)
    if self.input_state.draw then
        local mx, my = CAMERA:mousepos()
        mx, my = math.floor(mx), math.floor(my)
        local dx, dy = unpack(self.input_state.draw)
        dx, dy = math.floor(dx), math.floor(dy)

        local brush, ox, oy = brush.line(dx, dy, mx, my, BRUSHSIZE, PALETTE.colours[3])
        self:applyBrush(ox, oy, brush, self.input_state.lock)

        self.input_state.draw = {mx, my}
    end
end

function TileLayer:keypressed(key, isrepeat)
    if not isrepeat then
        if key == "lshift" then
            local mx, my = CAMERA:mousepos()
            self.input_state.lock = {self.tiles:gridCoords(mx, my)}
        elseif key == "lctrl" then
            self.input_state.cloning = {}
        end

        if key == "1" then BRUSHSIZE = 1 end
        if key == "2" then BRUSHSIZE = 2 end
        if key == "3" then BRUSHSIZE = 3 end

        if key == " " then
            PALETTE = Palette.generate(5)
        end
    end
end

function TileLayer:keyreleased(key)
    if key == "lshift" then
        self.input_state.lock = nil 
    elseif key == "lctrl" then
        self.input_state.cloning = nil
    end
end

function TileLayer:textinput(text)
end

function TileLayer:mousepressed(x, y, button)
    if button == "l" then
        if love.keyboard.isDown("lalt") then
            PALETTE.colours[3] = self:sample(x, y)
        else
            self.input_state.draw = {x, y}
            return true
        end
    end

    return false
end

function TileLayer:mousereleased(x, y, button)
    if button == "l" then
        self.input_state.draw = nil
    end
end

return TileLayer

local Class = require "hump.class"
local SparseGrid = require "sparsegrid"
local EditMode = require "editmode"
local Tileset = require "tileset"

local generators = require "generators"
local bresenham = require "bresenham"
local Brush = require "brush"
local colour = require "colour"

local TileMode = Class { __includes = EditMode, name = "tile placement" }
local PixelMode = Class { __includes = EditMode, name = "edit tiles" }
local WallsMode = Class { __includes = EditMode, name = "tile passability" }

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

    for item, x, y in generators.Grid.dungeon():items() do
        layer:set(item, x, y)
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

    for y, row in pairs(data.walls or {}) do
        for x, wall in pairs(row) do
            self.walls:set(wall or nil, tonumber(x), tonumber(y))
        end
    end
end

function TileLayer:serialise(saves)
    local tiles = {[0]={[0]=0}}

    for tile, x, y in self.tiles:items() do
        tiles[y] = tiles[y] or {[0]=0}
        tiles[y][x] = tile[1]
    end

    local walls = {[0]={[0]=false}}

    for wall, x, y in self.walls:items() do
        walls[y] = walls[y] or {[0]=false}
        walls[y][x] = wall
    end

    return {
        tileset = self.tileset:serialise(saves),
        tiles = tiles,
        walls = walls,
    }
end

function TileLayer:exportRegions(folder_path)
    local regions = self.tiles:regions()

    love.filesystem.createDirectory(folder_path .. "/regions")

    for i, region in ipairs(regions) do
        local text = ""
        local lasty

        for item, x, y in region:rectangle() do
            if lasty and lasty ~= y then
                text = text .. "\n"
            elseif lasty then
                text = text .. ","
            end

            lasty = y

            text = text .. (item and item[1] or 0)
        end

        text = text .. "\n"

        local file = love.filesystem.newFile(folder_path .. "/regions/" .. i .. ".txt", "w")
        file:write(text)
        file:close()
    end
end

function TileLayer:init()
    self.tileset = Tileset()
    self.batch = love.graphics.newSpriteBatch(love.graphics.newCanvas(32, 32), 7500)

    self.tiles = SparseGrid(32)
    self.walls = SparseGrid(32)
    
    self.active = true

    self.modes = {
        tile = TileMode(self),
        pixel = PixelMode(self),
        walls = WallsMode(self),
    }
end

function TileLayer:update(dt)
end

function TileLayer:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, self.active and 255 or 64)
    
    if not self.tileset.canvas.fake then
        self.batch:setTexture(self.tileset.canvas)
    else
        self.batch:setTexture(self.tileset.canvas.image)
    end

    love.graphics.draw(self.batch, 0, 0)
end

function TileLayer:get(gx, gy)
    local tile = self.tiles:get(gx, gy)

    return tile and tile[1] or nil
end

function TileLayer:set(index, gx, gy)
    local existing = self.tiles:get(gx, gy)
    local id = existing and existing[2]
    local size = 32

    if index and index ~= 0 then
        local quad = self.tileset.quads[index]

        if id then
            self.batch:set(id, quad, gx * size, gy * size)
        else
            id = self.batch:add(quad, gx * size, gy * size)
        end

        self.tiles:set({index, id}, gx, gy)
    else
        if id then
            self.batch:set(id, gx * size, gy * size, 0, 0, 0)
        end

        self.tiles:set(nil, gx, gy)
    end
end

function TileLayer:refresh()
    for tile, x, y in self.tiles:items() do
        self:set(tile[1], x, y)
    end
end

function TileLayer:gridCoords(x, y)
    return self.tiles:gridCoords(x, y)
end

function TileLayer:applyBrush(bx, by, brush, lock, cloning)
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

            if cloning and not cloning[key] and not locked then
                index = self.tileset:clone(index)
                self:set(index, gx + x, gy + y)
                cloning[key] = true
            end

            if index and not locked then
                self.tileset:applyBrush(index, brush, quad)
                self.tileset:refresh()
            end
        end
    end

    if cloning then self:refresh() end
end

function TileLayer:sample(x, y)
    local gx, gy, ox, oy = self:gridCoords(x, y)
    local index = self:get(gx, gy)

    return index and self.tileset:sample(index, ox, oy) or {0, 0, 0, 255}
end

function PixelMode:hover(x, y, dt)
    if self.state.draw then
        local dx, dy = unpack(self.state.draw)

        local brush, ox, oy = Brush.line(dx, dy, x, y, BRUSHSIZE, PALETTE.colours[3])
        self.layer:applyBrush(ox, oy, brush, self.state.lock, self.state.cloning)

        self.state.draw = {x, y}
    end
end

function PixelMode:draw(x, y)
    local gx, gy, ox, oy = self.layer.tiles:gridCoords(x, y)
    local tsize = 32

    local size = BRUSHSIZE
    local le = math.floor(size / 2)

    love.graphics.setColor(PALETTE.colours[3])
    love.graphics.rectangle("fill", math.floor(x)-le, math.floor(y)-le, size, size)

    if self.state.lock then
        love.graphics.setColor(colour.random(128, 255))

        local lx, ly = unpack(self.state.lock)
        love.graphics.rectangle("line", lx*tsize-0.5, ly*tsize-0.5, tsize+1, tsize+1)
    end
end

function PixelMode:mousepressed(x, y, button)
    if button == "l" then
        if love.keyboard.isDown("lalt") then
            PALETTE.colours[3] = self.layer:sample(x, y)
        else
            self.layer.tileset:snapshot(7)
            self.state.draw = {x, y} 
        end

        return true
    end

    return false
end

function PixelMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
    end
end

function PixelMode:keypressed(key, isrepeat)
    if not isrepeat then
        if key == "lshift" then
            local mx, my = CAMERA:mousepos()
            self.state.lock = {self.layer.tiles:gridCoords(mx, my)}
        elseif key == "lctrl" then
            self.state.cloning = {}
        end

        if key == "1" then BRUSHSIZE = 1 end
        if key == "2" then BRUSHSIZE = 2 end
        if key == "3" then BRUSHSIZE = 3 end

        if key == " " then
            PALETTE = generators.Palette.generate(5)
        end
    end
end

function PixelMode:keyreleased(key)
    if key == "lshift" then
        self.state.lock = nil 
    elseif key == "lctrl" then
        self.state.cloning = nil
    end
end

function TileMode:hover(x, y, dt)
    local gx, gy = self.layer:gridCoords(x, y)
    local tile = PROJECT.tilelayer:get(gx, gy)

    if self.state.draw then
        local ox, oy = unpack(self.state.draw)

        for lx, ly in bresenham.line(ox, oy, gx, gy) do
            self.layer:set(TILE, lx, ly)
        end

        self.state.draw = {gx, gy}
    elseif self.state.erase then
        self.layer:set(0, gx, gy)
    end

    if tile ~= PROJECT.tilelayer:get(gx, gy) then
        TILESOUND:stop()
        TILESOUND:play()
    end
end

function TileMode:draw(x, y)
    local gx, gy, ox, oy = self.layer:gridCoords(x, y)
    local size = 32

    local quad = self.layer.tileset.quads[TILE]

    love.graphics.rectangle("line", gx*size-0.5, gy*size-0.5, size+1, size+1)
    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.draw(self.layer.tileset.canvas, quad, gx * size, gy * size)
end

function TileMode:mousepressed(x, y, button)
    if button == "l" then
        local gx, gy = self.layer.tiles:gridCoords(x, y)

        if love.keyboard.isDown("lalt") then
            TILE = self.layer:get(gx, gy) or TILE
        else
            self.state.draw = {gx, gy}
        end

        return true
    elseif button == "r" then
        self.state.erase = true

        return true
    end

    return false
end

function TileMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
    elseif button == "r" then
        self.state.erase = nil
    end
end

function WallsMode:hover(x, y, dt)
    local gx, gy = self.layer:gridCoords(x, y)
    local wall = PROJECT.tilelayer.walls:get(gx, gy)

    if self.state.draw then
        self.layer.walls:set(true, gx, gy)
    elseif self.state.erase then
        self.layer.walls:set(nil, gx, gy)
    end

    if (self.state.draw and not wall) or (self.state.erase and wall) then
        TILESOUND:stop()
        TILESOUND:play()
    end
end

function WallsMode:draw(x, y)
    local size = 32

    for wall, x, y in self.layer.walls:items() do
        love.graphics.setColor(255, 0, 0, 128)
        love.graphics.rectangle("fill", x * size, y * size, size, size)
    end

    local gx, gy, ox, oy = self.layer:gridCoords(x, y)

    love.graphics.setColor(colour.random(128, 255))
    love.graphics.rectangle("line", gx*size-0.5, gy*size-0.5, size+1, size+1)
end

function WallsMode:mousepressed(x, y, button)
    if button == "l" then
        self.state.draw = true

        return true
    elseif button == "r" then
        self.state.erase = true

        return true
    end

    return false
end

function WallsMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
    elseif button == "r" then
        self.state.erase = nil
    end
end

return TileLayer

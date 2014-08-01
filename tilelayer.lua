local Class = require "hump.class"
local SparseGrid = require "sparsegrid"

local TileLayer = Class {}

function TileLayer:deserialise(rows)
    for y, row in pairs(rows) do
        for x, index in pairs(row) do
            if index > 0 then self:set(index, tonumber(x), tonumber(y)) end
        end
    end
end

function TileLayer:serialise()
    local rows = {}

    for tile, x, y in self.tiles:items() do
        rows[y] = rows[y] or {}
        rows[y][x] = tile[1]
    end

    return rows
end

function TileLayer:init(tileset)
    self.tileset = tileset
    self.batch = love.graphics.newSpriteBatch(tileset.canvas)

    self.tiles = SparseGrid(32)
end

function TileLayer:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)
    
    self.batch:setTexture(self.tileset.canvas)
    love.graphics.draw(self.batch, 0, 0)
end

function TileLayer:drawBrushCursor(x, y, size, colour, lock)
    local gx, gy, ox, oy = self:gridCoords(x, y)
    local tsize = 32

    if lock then
        local lx, ly = unpack(lock)
        love.graphics.rectangle("line", lx*tsize-0.5, ly*tsize-0.5, tsize+1, tsize+1)
    end

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

function TileLayer:applyBrush(bx, by, brush, lock, clone)
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

            if clone then
                index = self.tileset:clone(index)
                self:set(index, gx + x, gy + y)
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

return TileLayer

local Class = require "hump.class"
local SparseGrid = require "sparsegrid"

local TileLayer = Class {}

function TileLayer:deserialise(data)
    local x, y = 0, 0

    for row in string.gfind(data, "[^\n]+") do
        for index in string.gfind(row, "%d+") do
            local index = tonumber(index)

            if index > 0 then self:set(index, x, y) end

            x = x + 1
        end

        x = 0
        y = y + 1
    end
end

function TileLayer:serialise()
    local rows = {}
    for y=self.bounds[2],self.bounds[4] do
        local row = {}
        
        for x=self.bounds[1],self.bounds[3] do
            row[#row+1] = self:get(x, y) or 0
        end

        rows[#rows+1] = table.concat(row, ",")
    end

    return table.concat(rows, "\n")
end

function TileLayer:init(tileset)
    self.tileset = tileset
    self.batch = love.graphics.newSpriteBatch(tileset.canvas)

    self.tiles = SparseGrid()
    self.bounds = {0, 0, 0, 0}
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
    love.graphics.draw(tileset.canvas, quad, gx * size, gy * size)
end

function TileLayer:get(gx, gy)
    local tile = self.tiles:get(gx, gy)

    return tile and tile[1] or nil
end

function TileLayer:set(index, gx, gy)
    local quad = self.tileset.quads[index]
    local existing = self.tiles:get(gx, gy)
    local id = existing and existing[2] or nil

    local size = 32

    if id then
        self.batch:set(id, quad, gx * size, gy * size)
    else
        id = self.batch:add(quad, gx * size, gy * size)
    end

    self.tiles:set({index, id}, gx, gy)

    self.bounds[1] = math.min(self.bounds[1], gx)
    self.bounds[2] = math.min(self.bounds[2], gy)
    self.bounds[3] = math.max(self.bounds[3], gx)
    self.bounds[4] = math.max(self.bounds[4], gy)
end

function TileLayer:gridCoords(x, y)
    local size = 32
    local gx, gy = math.floor(x / size), math.floor(y / size)
    local ox, oy = math.floor(x % size), math.floor(y % size)

    return gx, gy, ox, oy
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

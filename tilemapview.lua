local Class = require "hump.class"
local Camera = require "hump.camera"

local TileMapView = Class {}

function TileMapView:init(tilemap)
    self.tilemap = tilemap

    self.camera = Camera(128, 128, 2)
end

function TileMapView:draw()
    self.camera:attach()

    self.tilemap:draw()

    self.camera:detach()
end

function TileMapView:grid_coords(px, py)
    local gx, gy = math.floor(px / 32), math.floor(py / 32)
    local ox, oy = math.floor(px % 32), math.floor(py % 32)

    return gx, gy, ox, oy
end

function TileMapView:pixel_coords(gx, gy, tx, ty)
    local tx, ty = tx or 0, ty or 0
    local px, py = self.camera:cameraCoords(gx * 32 + tx, gy * 32 + ty)

    return math.floor(px), math.floor(py)
end

function TileMapView:draw_tile_border(gx, gy)
    local px, py = self.camera:cameraCoords(gx * 32, gy * 32)
    local size = 32 * self.camera.scale

    love.graphics.rectangle("line", px - 1, py - 1, size + 2, size + 2)
end

function TileMapView:draw_tile_cursor(gx, gy, index)
    local quad = self.tilemap.tileset.quads[index]

    self.camera:attach()
    love.graphics.draw(self.tilemap.tileset.canvas, quad, gx * 32, gy * 32)
    self.camera:detach()
end

function TileMapView:draw_pixel(mx, my, colour, clone, lock)
    --[[
    local gx, gy, tx, ty = self:grid_coords(mx, my)
    local index = self.tilemap:get(gx, gy)

    if lock and (lock[1] ~= gx or lock[2] ~= gy) then return end

    if clone then
        index = self.tilemap.tileset:clone(index)
        self.tilemap:set(index, gx, gy)
    end

    if index then
        self.tilemap.tileset:renderTo(index, function()
            love.graphics.setColor(colour)
            love.graphics.rectangle("fill", tx, ty, 1, 1)
        end)
    end
    ]]

    local mx, my = self.camera:worldCoords(mx, my)

    local canvas = love.graphics.newCanvas(5, 5)
    canvas:renderTo(function()
        love.graphics.setColor(colour)
        love.graphics.rectangle("fill", 1, 1, 3, 3)
    end)

    self:apply_brush(mx-2, my-2, canvas)
end

function TileMapView:apply_brush(bx, by, canvas, lock, clone)
    -- convert to world coordinates
    local gx, gy, tx, ty = self:grid_coords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile TODO: (if unlocked)
    local bw, bh = canvas:getDimensions()
    local size = 32

    local gw, gh = math.ceil((bw + tx) / size), math.ceil((bh + ty) / size)
    local quad = love.graphics.newQuad(0, 0, size, size, bw, bh)

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local index = self.tilemap:get(gx + x, gy + y)
            quad:setViewport(-tx + x * size, -ty + y * size, size, size)

            local locked = lock and (lock[1] ~= x+gx or lock[2] ~= y+gy)

            if clone then
                index = self.tilemap.tileset:clone(index)
                self.tilemap:set(index, gx + x, gy + y)
            end 

            if index and not locked then
                self.tilemap.tileset:renderTo(index, function()
                    love.graphics.draw(canvas, quad, 0, 0)
                end)
            end
        end
    end
end

function TileMapView:sample(mx, my)
    local gx, gy, tx, ty = self:grid_coords(mx, my)
    local index = self.tilemap:get(gx, gy)

    if index then
        return self.tilemap.tileset:sample(index, tx, ty)
    else
        return {0, 0, 0, 255}
    end
end

return TileMapView

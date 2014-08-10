local Class = require "hump.class"
local common = require "common"

local Sprite = Class {}

function Sprite:init(sprite)
    self.canvas = sprite and common.cloneCanvas(sprite.canvas) or love.graphics.newCanvas(32, 32)
    self.pivot = {16, 16}
    self.size = {32, 32}
end

function Sprite:draw(x, y, a, s)
    local px, py = unpack(self.pivot)
    love.graphics.draw(self.canvas, x, y, a or 0, s or 1, s or 1, px, py)
end

function Sprite:applyBrush(bx, by, brush, lock)
    local px, py = unpack(self.pivot)
    bx, by = bx + px, by + py

    if lock then
        local bw, bh = brush:getDimensions()
        local brush_rect = {bx, by, bw-1, bh-1}
        local sw, sh = self.canvas:getDimensions()
        local sprite_rect = {0, 0, sw, sh}
        
        local rect = common.expandRectangle(sprite_rect, brush_rect)
        dx, dy, nw, nh = unpack(rect)

        if dx < 0 or dy < 0 or nw ~= sw or nh ~= sh then
            self.canvas = common.resizeCanvas(self.canvas, nw, nh, -dx, -dy)
            self.pivot = {px - dx, py - dy}
            self.size = {nw, nh}
        end

        bx, by = bx - dx, by - dy
    end

    brush:apply(self.canvas, nil, bx, by)
end

function Sprite:sample(x, y)
    local px, py = unpack(self.pivot)
    return {self.canvas:getPixel(x + px, y + py)}
end

return Sprite

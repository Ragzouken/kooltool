local Class = require "hump.class"
local common = require "utilities.common"

local Event = require "utilities.event"

local Sprite = Class {
    name = "Generic Sprite",
    type = "Sprite",
    alpha = 1,
}

function Sprite:serialise(resources)
    local full, file = resources:file(self, "sprite.png")
    self.canvas:getImageData():encode(full)

    return {
        file = file,
        pivot = self.pivot,
    }
end

function Sprite:deserialise(resources, data)
    self.canvas = common.loadCanvas(resources:path(data.file))
    self.pivot = data.pivot
end

function Sprite:init()
    self.resized = Event()
end

function Sprite:finalise()
end

function Sprite:blank(w, h)
    self.canvas = love.graphics.newCanvas(w, h)
    self.pivot = {w/2, w/2}
    
    self.canvas:renderTo(function()
        love.graphics.circle("fill", w/2, h/2, math.max(w/2, h/2), 32)
    end)
end

function Sprite:draw(x, y, a, s)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255 * self.alpha)

    local px, py = unpack(self.pivot)
    
    love.graphics.draw(self.canvas,
                       x or 0, y or 0,
                       a or 0,
                       s or 1, s or 1,
                       px, py)
end

function Sprite:applyBrush(bx, by, brush, lock)
    local px, py = unpack(self.pivot)
    --bx, by = bx + px, by + py

    if lock then
        local bw, bh = brush:getDimensions()
        local brush_rect = {bx, by, bw, bh}
        local sw, sh = self.canvas:getDimensions()
        local sprite_rect = {0, 0, sw, sh}
        
        local rect = common.expandRectangle(sprite_rect, brush_rect)
        local dx, dy, nw, nh = unpack(rect)

        if dx < 0 or dy < 0 or nw ~= sw or nh ~= sh then
            self.canvas = common.resizeCanvas(self.canvas, nw, nh, -dx, -dy)
            self.pivot = {px - dx, py - dy}
        end

        bx, by = bx - dx, by - dy

        self.resized:fire { dx    = dx,       dy   = dy, 
                            nw    = nw,       nh   = nh,
                            left  = -dx,      up   = -dy,
                            right = nw-sw+dx, down = nh-sh+dy }
    end

    brush:apply(self.canvas, nil, bx, by)
end

function Sprite:sample(x, y)
    local px, py = unpack(self.pivot)
    return {self.canvas:getPixel(math.floor(x + px), math.floor(y + py))}
end

return Sprite

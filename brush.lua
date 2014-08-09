local Class = require "hump.class"

local bresenham = require "bresenham"

local Brush = Class {}

function Brush.line(x1, y1, x2, y2, size, colour)
    local le = math.floor(size / 2)
    local re = size - le

    local w, h = math.abs(x2 - x1), math.abs(y2 - y1)
    local x, y = math.min(x1, x2), math.min(y1, y2)

    local brush = Brush(w+1+size, h+1+size, function()
        love.graphics.push()
        love.graphics.translate(-x, -y)

        love.graphics.setColor(colour or {0, 0, 0, 0})
        local sx, sy = x1+le, y1+le
        local ex, ey = x2+le, y2+le

        for x, y in bresenham.line(sx, sy, ex, ey) do
            love.graphics.rectangle("fill", x - le, y - le, size, size)
        end

        love.graphics.pop()
    end, not colour)

    love.graphics.setBlendMode("alpha")

    return brush, x-le, y-le
end

function Brush:init(w, h, render, mode)
    self.canvas = love.graphics.newCanvas(w, h)
    
    if mode == "erase" then
        self.canvas:clear(255, 255, 255, 255)
        love.graphics.setBlendMode("replace")
    end

    self.canvas:renderTo(render)
end

function Brush:draw(quad, ox, oy, ...)
    local bw, bh = self.canvas:getDimensions()
    local x, y, w, h = quad:getViewport()

    local dx1, dy1 = math.max(x, 0), math.max(y, 0)
    local dx2, dy2 = math.min(x+w, bw), math.min(y+h, bh)

    quad:setViewport(dx1, dy1, dx2 - dx1, dy2 - dy1)

    love.graphics.draw(self.canvas, quad, ox+dx1-x, oy+dy1-y, ...)

    quad:setViewport(x, y, w, h)
end

return Brush

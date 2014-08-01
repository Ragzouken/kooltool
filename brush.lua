local bresenham = require "bresenham"

local function line(x1, y1, x2, y2, size, colour)
    local le = math.floor(size / 2)
    local re = size - le

    local w, h = math.abs(x2 - x1), math.abs(y2 - y1)
    local x, y = math.min(x1, x2), math.min(y1, y2)

    local brush = love.graphics.newCanvas(w+2+1+size, h+2+1+size)

    if not colour then
        brush:clear(255, 255, 255, 255)
        love.graphics.setBlendMode("replace")
    end

    brush:renderTo(function()
        love.graphics.push()
        love.graphics.translate(1-x, 1-y)

        love.graphics.setColor(colour or {0, 0, 0, 0})
        local sx, sy = x1+le, y1+le
        local ex, ey = x2+le, y2+le

        for x, y in bresenham.line(sx, sy, ex, ey) do
            love.graphics.rectangle("fill", x - le, y - le, size, size)
        end

        love.graphics.pop()
    end)

    love.graphics.setBlendMode("alpha")

    return brush, x-1-le, y-1-le
end

return {
    line = line,
}

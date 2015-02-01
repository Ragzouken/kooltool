local Brush = require "tools.brush"

local sprite = {}

function sprite.mess(dimensions, palette)
    local Sprite = require "components.sprite"

    local w, h = unpack(dimensions)
    local sprite = Sprite()

    local canvas = love.graphics.newCanvas(w, h)
    local s = math.max(w, h)

    local function line(x1, y1, x2, y2, size, colour)
        local brush, x, y = Brush.line(x1*w, y1*h, x2*w, y2*h, size, colour)
        brush:apply(canvas, false, x, y)
    end

    local function branch(x, y, depth)
        x, y = x % 1, y % 1

        local a1, d1 = math.random() * math.pi * 2, math.random()
        local a2, d2 = math.random() * math.pi * 2, math.random()

        local x1, y1 = x + math.cos(a1) * d1, y + math.sin(a1) * d1
        local x2, y2 = x + math.cos(a2) * d2, y + math.sin(a2) * d2

        line(x, y, x1, y1, math.random(4), palette.colours[math.random(4,9)])
        line(x, y, x2, y2, math.random(4), palette.colours[math.random(4,9)])

        if 1 / depth > math.random() then branch(x1, y1, depth+1) end
        if 1 / depth > math.random() then branch(x2, y2, depth+1) end
    end

    for i=1,3 do
        branch(0.5, 0.5, 1)
    end

    sprite.canvas = canvas
    sprite.pivot = {math.floor(w/2), math.floor(h/2)}

    return sprite
end

return sprite

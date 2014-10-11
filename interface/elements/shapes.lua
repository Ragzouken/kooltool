local Class = require "hump.class"

local Plane = Class {}

function Plane:init(params)
    self:move_to {x = params.x or 0, y = params.y or 0}
end

function Plane:draw()
end

function Plane:contains(x, y)
    return true
end

function Plane:move_to(params)
    self.x, self.y = params.x, params.y
end



local Rectangle = Class {}

function Rectangle:init(params)
    self.w, self.h = params.w, params.h

    self:move_to {x = params.x, y = params.y,
                  pivot = params.pivot,
                  anchor = params.anchor}
end

function Rectangle:draw(mode)
    local x, y = self.x, self.y
    local w, h = self.w, self.h
    
    love.graphics.rectangle(mode, x+0.5, y+0.5, w-1, h-1)
end

function Rectangle:contains(x, y)
    local x1, y1, x2, y2 = self.x, self.y, self.x + self.w, self.y + self.h
    
    return (x1 <= x and x <= x2) and (y1 <= y and y <= y2)
end

function Rectangle:move_to(params)
    local px, py = unpack(params.pivot or {0, 0})

    if params.anchor then
        local ax, ay = unpack(params.anchor)

        px, py = self.w * ax, self.h * ay
    end

    self.x, self.y = params.x - px, params.y - py
end

function Rectangle:coords(params)
    local px, py = unpack(params.pivot or {0, 0})

    if params.anchor then
        local ax, ay = unpack(params.anchor)

        px, py = self.w * ax, self.h * ay
    end

    return self.x + px, self.y + py
end

return {
    Plane = Plane,
    Rectangle = Rectangle,
}

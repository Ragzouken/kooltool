local Class = require "hump.class"

local function rect_rect(a, b)
    if a.x > b.x + b.w or a.y > b.y + b.h then return false end
    if b.x > a.x + a.w or b.y > a.y + a.h then return false end

    return true
end

local Shape = Class {}

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

function Rectangle.Null()
    return Rectangle { x = 0, y = 0, w = 0, h = 0 }
end

function Rectangle:init(params)
    self.w, self.h = params.w, params.h

    self:move_to {x = params.x, y = params.y,
                  pivot = params.pivot,
                  anchor = params.anchor}
end

function Rectangle:draw(mode)
    local x, y = self.x, self.y
    local w, h = self.w, self.h
    
    love.graphics.rectangle(mode, x, y, w, h)
end

function Rectangle:contains(x, y)
    local x1, y1, x2, y2 = self.x, self.y, self.x + self.w, self.y + self.h
    
    return (x1 <= x and x <= x2) and (y1 <= y and y <= y2)
end

function Rectangle:move_to(params)
    local px, py = unpack(params.pivot or {0, 0})

    if params.anchor then
        px, py = self:pivot(unpack(params.anchor))
    end

    -- TODO: this shouldn't floor, probably, but needs to so draw has int coords
    self.x, self.y = math.floor(params.x - px), math.floor(params.y - py)
end

function Rectangle:grow(params)
    self.w = self.w + (params.left or 0) + (params.right or 0)
    self.h = self.h + (params.up   or 0) + (params.down  or 0)

    self.x = self.x - (params.left or 0)
    self.y = self.y - (params.up   or 0)
end

function Rectangle:coords(params)
    local px, py = unpack(params.pivot or {0, 0})

    if params.anchor then
        px, py = self:pivot(unpack(params.anchor))
    end

    return self.x + px, self.y + py
end

function Rectangle:pivot(ax, ay)
    return self.w * ax, self.h * ay
end

return {
    Plane = Plane,
    Rectangle = Rectangle,

    rect_rect = rect_rect,
}

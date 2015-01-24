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
    return Rectangle { }
end

function Rectangle:init(params)
    self.x, self.y = params.x or 0, params.y or 0
    self.w, self.h = params.w or 0, params.h or 0

    self.anchor = params.anchor
    self.pivot = params.pivot

    self:move_to { x = params.x or 0, y = params.y or 0 }
end

function Rectangle:draw(mode, padding, debug)
    padding = padding or self.padding or 0

    local x, y = self.x - padding,     self.y - padding
    local w, h = self.w + padding * 2, self.h + padding * 2
    
    love.graphics.rectangle(mode,
                            math.floor(x)+0.5, math.floor(y)+0.5,
                            math.floor(w), math.floor(h))
end

function Rectangle:contains(x, y)
    local x1, y1, x2, y2 = self.x, self.y, self.x + self.w, self.y + self.h
    
    return (x1 <= x and x <= x2) and (y1 <= y and y <= y2)
end

function Rectangle:move_to(params)
    local px, py = unpack(params.pivot or self.pivot or {0, 0})

    if params.anchor or self.anchor then
        px, py = self:pivot_(unpack(params.anchor or self.anchor))
    end

    -- TODO: this shouldn't floor, probably, but needs to so draw has int coords
    self.x, self.y = math.floor(params.x - px), math.floor(params.y - py)
end

function Rectangle:set(x, y, w, h)
    self.x, self.y = x, y
    self.w, self.h = w, h
end

function Rectangle:get()
    return self.x, self.y, self.w, self.h
end

function Rectangle:include(rectangle)
    local ox, oy, ow, oh = self:get()

    self.x = math.min(ox, rectangle.x)
    self.y = math.min(oy, rectangle.y)
    self.w = math.max(ox + self.w, rectangle.x + rectangle.w) - self.x
    self.h = math.max(oy + self.h, rectangle.y + rectangle.h) - self.y
end

function Rectangle:intersect(rectangle)
    local ox, oy, ow, oh = self:get()

    self.x = math.max(ox, rectangle.x)
    self.y = math.max(oy, rectangle.y)
    self.w = math.min(ox + self.w, rectangle.x + rectangle.w) - self.x
    self.h = math.min(oy + self.h, rectangle.y + rectangle.h) - self.y
end

function Rectangle:grow(params)
    self.w = self.w + (params.left or 0) + (params.right or 0)
    self.h = self.h + (params.up   or 0) + (params.down  or 0)

    self.x = self.x - (params.left or 0)
    self.y = self.y - (params.up   or 0)
end

function Rectangle:coords(params)
    params = params or {}
    
    local px, py = unpack(params.pivot or {0, 0})

    if params.anchor then
        px, py = self:pivot_(unpack(params.anchor))
    end

    return self.x + px, self.y + py
end

function Rectangle:pivot_(ax, ay)
    return self.w * ax, self.h * ay
end

function Rectangle:to_local(x, y)
    return x - self.x, y - self.y
end

function Rectangle:to_world(x, y)
    return x + self.x, y + self.y
end

return {
    Plane = Plane,
    Rectangle = Rectangle,

    rect_rect = rect_rect,
}

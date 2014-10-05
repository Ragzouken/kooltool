local Class = require "hump.class"

local Plane = Class {}

function Plane:init(x, y)
    self.x, self.y = x or 0, y or 0
end

function Plane:contains(x, y)
    return true
end

function Plane:anchor()
    return self.x, self.y
end

function Plane:draw()
end

function Plane:moveTo(x, y)
    self.x, self.y = x, y
end

local Rectangle = Class {}

function Rectangle:init(x, y, w, h, pivot)
    self.pivot = pivot or {0, 0}
    
    self.x, self.y = x, y
    self.w, self.h = w, h
end

function Rectangle:contains(x, y)
    local x1, y1, x2, y2 = self:coords()
    
    return (x1 <= x and x <= x2) and (y1 <= y and y <= y2)
end

function Rectangle:anchor()
    local px, py = unpack(self.pivot)
    local w, h = self.w, self.h
    
    local x = self.x - (w / 2) * (px + 1)
    local y = self.y - (h / 2) * (py + 1)
    
    return x, y
end

function Rectangle:draw(mode)
    local x1, y1, x2, y2 = self:coords()
    
    love.graphics.rectangle(mode, x1, y1, x2-x1-1, y2-y1-1)
end

function Rectangle:coords()
    local px, py = unpack(self.pivot)
    
    local w, h = self.w, self.h
    local x = self.x - (w / 2) * (px + 1)
    local y = self.y - (h / 2) * (py + 1)
    
    return x, y, x+w, y+h
end

return {
    Plane = Plane,
    Rectangle = Rectangle,
}

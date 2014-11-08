local Class = require "hump.class"

local directions = {
    { 1,  0},
    { 0,  1},
    {-1,  0},
    { 0, -1},
}

local Turtle = Class {}

function Turtle:init(x, y, direction)
    self.x, self.y = x, y
    self.direction = direction
end

function Turtle:forward()
    local vx, vy = unpack(directions[self.direction + 1])
    self.x, self.y = self.x + vx, self.y + vy
end

function Turtle:spin()
    self.direction = math.random(0, 3)
end

return {
    Turtle = Turtle,
}

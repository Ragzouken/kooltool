local Class = require "hump.class"
local Timer = require "hump.timer"

local Player = Class {}

function Player:init(entity)
    self.timer = Timer()
    self.entity = entity
end

function Player:update(dt)
    self.timer:update(dt)
end

local directions = {
    {0, -1},
    {-1, 0},
    {0, 1},
    {1, 0},

    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function Player:rando()
    self:move(directions[love.math.random(4)])
end

function Player:move(vector)
    local vx, vy = unpack(vector)
    local gx, gy = PROJECT.layers.surface.tilemap:gridCoords(self.entity.x, self.entity.y)
    local dx, dy = gx+vx, gy+vy

    local tile = PROJECT.layers.surface:getTile(dx, dy)
    local wall = PROJECT.layers.surface:getWall(dx, dy)

    if not wall and not self.movement then
        local period = self.speed
        local t = 0
        local x, y = self.entity.x, self.entity.y

        self.movement = self.timer:do_for(period, function(dt)
            t = t + dt
            local u = t / period

            self.entity.x, self.entity.y = x + vx * 32 * u, y + vy * 32 * u
        end, function()
            self.entity.x, self.entity.y = x + vx * 32, y + vy * 32
            self.movement = nil
        end)
    end
end

function Player:keypressed(key, isrepeat)
    if not self.movement and directions[key] then
        self:move(directions[key])
    end
end

return Player

local Class = require "hump.class"
local Timer = require "hump.timer"

local Player = Class {}

function Player:init(entity, walls)
    self.timer = Timer()
    self.entity = entity
    self.walls = walls
end

function Player:update(dt)
    self.timer:update(dt)
end

local directions = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function Player:keypressed(key, isrepeat)
    if not self.movement and directions[key] and not self.movement then
        local vx, vy = unpack(directions[key])
        local gx, gy = self.walls:gridCoords(self.entity.x, self.entity.y)

        if not self.walls:get(gx+vx, gy+vy) then
            local period = 0.25
            local t = 0
            local x, y = self.entity.x, self.entity.y

            self.movement = self.timer:do_for(period, function(dt)
                t = t + dt
                local u = t / period

                self.entity.x, self.entity.y = x + vx * 32 * u, y + vy * 32 * u
            end, function()
                self.movement = nil
            end)
        end
    end
end

return Player

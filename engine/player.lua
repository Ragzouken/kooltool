local Class = require "hump.class"
local Timer = require "hump.timer"

local shapes = require "collider.shapes"
local Player = Class {}

local speech = love.audio.newSource("sounds/tempspeech.wav")

local controls = {
    up = {0, -1},
    left = {-1, 0},
    down = {0, 1},
    right = {1, 0},
}

function Player:init(game, entity)
    self.game = game
    self.timer = Timer()
    self.entity = entity

    self.tx, self.ty = PROJECT.layers.surface.tilemap:gridCoords(entity.x, entity.y)

    self.ox, self.oy = self.entity.x, self.entity.y

    local annotations = PROJECT.layers.annotation
    local w, h = unpack(self.entity.sprite.size)
    local px, py = unpack(self.entity.sprite.pivot)
    local x, y = self.entity.x-px, self.entity.y-py

    self.notes = {}

    local x1, y1, x2, y2 = x, y, x+w, y+h
    self.shape = shapes.newPolygonShape(x1, y1, x1, y2, x2, y2, x2, y1)
    self.shape:moveTo(x+w/2, y+h/2)

    self.tags = {}
    self.speech = {}

    for shape in pairs(annotations.collider:shapesInRange(x, y, x+w, y+h)) do
        if shape:collidesWith(self.shape) then
            local text = shape.notebox.text
            
            if text:sub(1, 1) == "[" then
                self.tags[text:lower()] = true
            else
                table.insert(self.speech, text)
            end
        end
    end
end

function Player:update(dt)
    self.timer:update(dt)

    if not self.movement then
        if self == self.game.player then
            for key, vector in pairs(controls) do
                if love.keyboard.isDown(key) then
                    self:move(vector, true)
                end
            end
        elseif self.game.player and not self.tags["[stop]"] then
            local player = self.game.player.entity
            local dx, dy = self.entity.x - player.x, self.entity.y - player.y
            local d = math.sqrt(dx * dx + dy * dy)

            if d > 64 then
                self:rando()
            end
        end
    end
end

function Player:draw()
end

local directions = {
    {0, -1},
    {-1, 0},
    {0, 1},
    {1, 0},
}

function Player:rando()
    self:move(directions[love.math.random(4)])
end

function Player:move(vector, input)
    local vx, vy = unpack(vector)
    local gx, gy = PROJECT.layers.surface.tilemap:gridCoords(self.entity.x, self.entity.y)
    local dx, dy = gx+vx, gy+vy

    local wall = PROJECT.layers.surface:getWall(dx, dy)
    local occupier = self.game.occupied:get(dx, dy)

    if occupier and self == self.game.player then
        self.game.TEXT = occupier.speech[love.math.random(#occupier.speech)]
        speech:play()
        return
    end

    if not wall and not self.movement then
        local period = self.speed
        local t = 0
        local x, y = self.entity.x, self.entity.y

        self.tx, self.ty = dx, dy

        self.movement = self.timer:do_for(period, function(dt)
            t = t + dt
            local u = t / period

            self.entity:moveTo(x + vx * 32 * u, y + vy * 32 * u)
        end, function()
            self.entity:moveTo(x + vx * 32, y + vy * 32)
            self.movement = nil
        end)
    end
end

return Player

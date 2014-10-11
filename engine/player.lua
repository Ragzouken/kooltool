local Class = require "hump.class"
local Timer = require "hump.timer"

local shapes = require "interface.elements.shapes"
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

    local cx, cy = entity.shape:coords { anchor = {0.5, 0.5} }

    self.tx, self.ty = PROJECT.layers.surface.tilemap:gridCoords(cx, cy)
    self.ox, self.oy = cx, cy

    local annotations = PROJECT.layers.annotation
    local w, h = self.entity.shape.w, self.entity.shape.h
    local px, py = unpack(self.entity.sprite.pivot)
    local x, y = cx-px, cy-py

    self.notes = {}

    local x1, y1, x2, y2 = x, y, x+w, y+h

    self.tags = {}
    self.speech = {}

    for entity in pairs(PROJECT.layers.surface.entities) do
        for notebox in pairs(PROJECT.layers.annotation.noteboxes) do
            if shapes.rect_rect(entity.shape, notebox.shape) then
                local text = notebox.text
                
                if text:sub(1, 1) == "[" then
                    self.tags[text:lower()] = true
                else
                    table.insert(self.speech, text)
                end
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
            local px, py = self.game.player.entity.shape:coords { anchor = {0.5, 0.5} }
            local cx, cy = self.entity.shape:coords { anchor = {0.5, 0.5} }
            local dx, dy = cx - px, cy - py
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
    local cx, cy = self.entity.shape:coords { anchor = {0.5, 0.5} }
    local gx, gy = PROJECT.layers.surface.tilemap:gridCoords(cx, cy)

    local vx, vy = unpack(vector)
    local dx, dy = gx+vx, gy+vy

    local wall = PROJECT.layers.surface:getWall(dx, dy)
    local occupier = self.game.occupied:get(dx, dy)

    if occupier and self == self.game.player then
        if #occupier.speech > 0 then
            self.game.TEXT = occupier.speech[love.math.random(#occupier.speech)]
        end
        speech:play()
        if occupier.tags["[pop]"] then occupier:destroy() end
        return
    end

    if not wall and not self.movement then
        local period = self.speed
        local t = 0
        local x, y = self.entity.shape:coords { anchor = {0.5, 0.5} }

        self.tx, self.ty = dx, dy

        self.movement = self.timer:do_for(period, function(dt)
            t = t + dt
            local u = t / period

            self.entity:move_to { x = x + vx * 32 * u, y = y + vy * 32 * u, anchor={0.5, 0.5}}
        end, function()
            self.entity:move_to { x = x + vx * 32, y = y + vy * 32, anchor={0.5, 0.5}}
            self.movement = nil
        end)
    end
end

function Player:destroy()
end

return Player

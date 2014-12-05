local Class = require "hump.class"
local Timer = require "hump.timer"

local parse = require "engine.parse"

local shapes = require "interface.elements.shapes"
local Player = Class {
    speed = 0.5,
}

local speech = love.audio.newSource("sounds/tempspeech.wav")

local controls = {
    up    = { 0, -1},
    left  = {-1,  0},
    down  = { 0,  1},
    right = { 1,  0},
}

function Player:init(game, entity)
    self.game = game
    self.timer = Timer()
    self.entity = entity

    local layers = self.game.project.layers

    self.va = 0
    self.a = 0

    self.ox, self.oy = entity.x, entity.y
    self.tx, self.ty = layers.surface.tilemap:gridCoords(entity.x, entity.y)

    local annotations = layers.annotation

    self.notes = {}

    self.speech = {}
    self.events = {}
    self.locals = { path = "?", ghost = "no" }

    self.pathprogress = 1

    if self.entity.script then
        for notebox in pairs(self.entity.script.annotation.noteboxes) do
            local action = parse.test(notebox.text)

            if action then
                action.locals = self.locals
                action.entity = self

                local label, global = unpack(action.trigger)
                local events = global and game.events or self.events

                events[label] = events[label] or {}
                table.insert(events[label], action)
            else
                print("invalid action") print(notebox.text)
            end
        end
    end

    self.active = true
end

function Player:trigger(event)
    if event == "remove" then 
        self:destroy()
    elseif event == "player" then
        self.game.player = self
    elseif event == "bring" then
        local tw, th = unpack(self.game.project.layers.surface.tileset.dimensions)
        local player = self.game.player
        player.tx, player.ty = self.tx, self.ty
        player.entity:move_to { x = (player.tx + 0.5) * tw, 
                                y = (player.ty + 0.5) * th }
        if player.movement then player.timer:cancel(player.movement) end
        player.movement = nil
    end

    for i, action in ipairs(self.events[event] or {}) do
        if self.game:check(action) then
            table.insert(self.game.queue, action)
        end
    end
end

function Player:update(dt)
    self.timer:update(dt)

    local number = tonumber(self.locals.spin)
    self.va = math.pi * 2 * (number or self.va)

    self.a = self.a + dt * self.va
    self.entity.a = self.a

    if not self.movement then
        if self == self.game.player then
            for key, vector in pairs(controls) do
                if love.keyboard.isDown(key) then
                    self:move(vector, true)
                end
            end
        elseif self.game.player then
            self:rando()
        end
    end
end

function Player:draw()
end

local directions = {
    { 0, -1},
    {-1,  0},
    { 0,  1},
    { 1,  0},

    ["^"] = { 0, -1},
    ["<"] = {-1,  0},
    ["v"] = { 0,  1},
    [">"] = { 1,  0},
    ["."] = { 0,  0},
}

function Player:rando()
    if self.locals.path and #self.locals.path >= 1 then
        if self.pathprogress > #self.locals.path then
            self.pathprogress = 1
        end

        local direction = self.locals.path:sub(self.pathprogress, self.pathprogress)

        if direction == "?" then direction = love.math.random(4) end

        self.pathprogress = self.pathprogress + 1

        self:move(directions[direction])
    end
end

function Player:move(vector, input)
    local cx, cy = self.entity.x, self.entity.y
    local gx, gy = self.game.project.layers.surface.tilemap:gridCoords(cx, cy)

    local vx, vy = unpack(vector)
    local dx, dy = gx+vx, gy+vy

    local wall = self.game.project.layers.surface:getWall(dx, dy)
    local occupier = self.game.occupied:get(dx, dy)

    if occupier and occupier.locals.ghost == "no" and self.locals.ghost == "no" then
        if not occupier.blocked and self == self.game.player then
            occupier:trigger("bump")

            occupier.blocked = true
            occupier.timer:add(0.1, function() occupier.blocked = false end)
        end

        return
    end

    local tw, th = unpack(self.game.project.layers.surface.tileset.dimensions)

    if not wall and not self.movement then
        local period = 1 / (tonumber(self.locals.speed) or 2)
        local t = 0

        self.tx, self.ty = dx, dy

        self.movement = self.timer:do_for(period, function(dt)
            t = t + dt
            local u = t / period

            self.entity:move_to { x = cx + vx * tw * u, y = cy + vy * th * u}
        end, function()
            self.entity:move_to { x = cx + vx * tw, y = cy + vy * th}
            self.movement = nil
        end)
    end
end

function Player:destroy()
    self.active = false
    self.entity.active = false
    self.game.occupied:set(nil, self.tx, self.ty)
end

return Player

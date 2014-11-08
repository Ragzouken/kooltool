local Class = require "hump.class"
local Timer = require "hump.timer"

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

    self.va = 0
    self.a = 0

    self.ox, self.oy = entity.shape:coords()

    local cx, cy = entity.shape:coords { pivot = entity.sprite.pivot }

    self.tx, self.ty = PROJECT.layers.surface.tilemap:gridCoords(cx, cy)

    local annotations = PROJECT.layers.annotation
    local w, h = self.entity.shape.w, self.entity.shape.h
    local px, py = unpack(self.entity.sprite.pivot)
    local x, y = cx-px, cy-py

    self.notes = {}

    local x1, y1, x2, y2 = x, y, x+w, y+h

    self.tags = {
        path = "?",
    }

    self.speech = {}

    for notebox in pairs(PROJECT.layers.annotation.noteboxes) do
        if shapes.rect_rect(entity.shape, notebox.shape) then
            local key, value = parse_note(notebox.text)

            if key then
                self.tags[key] = value
            else
                table.insert(self.speech, notebox.text)
            end
        end
    end

    if self.tags.spin then 
        local number = tonumber(self.tags.spin) or 1

        self.va = math.pi * 2 * (number or 1)
    end

    self.active = true

    if self.tags.path then
        self.pathprogress = 1
        self.tags.path = self.tags.path:gsub("[^%^<>v%?%.]", "")
    end

    if self.tags.speed then
        local number = tonumber(self.tags.speed) or 1

        self.speed = 1 / number
    end
end

function Player:update(dt)
    self.timer:update(dt)

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
    if self.tags.path and #self.tags.path >= 1 then
        local direction = self.tags.path:sub(self.pathprogress, self.pathprogress)

        if direction == "?" then direction = love.math.random(4) end

        self.pathprogress = self.pathprogress + 1
        if self.pathprogress > #self.tags.path then
            self.pathprogress = 1
        end

        self:move(directions[direction])
    end
end

function Player:move(vector, input)
    local cx, cy = self.entity.shape:coords { pivot = self.entity.sprite.pivot }
    local gx, gy = PROJECT.layers.surface.tilemap:gridCoords(cx, cy)

    local vx, vy = unpack(vector)
    local dx, dy = gx+vx, gy+vy

    local wall = PROJECT.layers.surface:getWall(dx, dy)
    local occupier = self.game.occupied:get(dx, dy)

    if occupier then
        if self == self.game.player then
            if #occupier.speech > 0 then
                self.game.TEXT = occupier.speech[love.math.random(#occupier.speech)]
            end
            speech:play()
            if occupier.tags.pop then occupier:destroy() end
            if occupier.tags.swap then self.game.player = occupier end
        end

        return
    end

    local tw, th = unpack(PROJECT.layers.surface.tileset.dimensions)

    if not wall and not self.movement then
        local period = self.speed
        local t = 0
        local x, y = self.entity.shape:coords()

        self.tx, self.ty = dx, dy

        self.movement = self.timer:do_for(period, function(dt)
            t = t + dt
            local u = t / period

            self.entity:move_to { x = x + vx * tw * u, y = y + vy * th * u}
        end, function()
            self.entity:move_to { x = x + vx * tw, y = y + vy * th}
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

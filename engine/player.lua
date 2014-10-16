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

    self.va = 0
    self.a = 0

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

    local function parse_note(text)
        local code = string.match(text, "%[(.+)%]")

        if code then
            local key, value

            if code:find("=") then
                key, value = string.match(code, "(.*)=(.*)")
            else
                key, value = code, true
            end

            self.tags[key:lower()] = value
        else
            table.insert(self.speech, text)
        end
    end

    for notebox in pairs(PROJECT.layers.annotation.noteboxes) do
        if shapes.rect_rect(entity.shape, notebox.shape) then
            parse_note(notebox.text)
        end
    end

    if self.tags.spin then self.va = math.pi end

    self.active = true

    if self.tags.path then
        self.pathprogress = 1
        self.tags.path = self.tags.path:gsub("[^%^<>v%?%.]", "")
        print(self.tags.path)
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
        elseif self.game.player and not self.tags.stop then
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
    local direction = love.math.random(4)

    if self.tags.path and #self.tags.path >= 1 then
        direction = self.tags.path:sub(self.pathprogress, self.pathprogress)

        if direction == "?" then direction = love.math.random(4) end

        self.pathprogress = self.pathprogress + 1
        if self.pathprogress > #self.tags.path then
            self.pathprogress = 1
        end
    end

    self:move(directions[direction])
end

function Player:move(vector, input)
    local cx, cy = self.entity.shape:coords { anchor = {0.5, 0.5} }
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
        local x, y = self.entity.shape:coords { anchor = {0.5, 0.5} }

        self.tx, self.ty = dx, dy

        self.movement = self.timer:do_for(period, function(dt)
            t = t + dt
            local u = t / period

            self.entity:move_to { x = x + vx * tw * u, y = y + vy * th * u, anchor={0.5, 0.5}}
        end, function()
            self.entity:move_to { x = x + vx * tw, y = y + vy * th, anchor={0.5, 0.5}}
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

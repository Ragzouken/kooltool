local Class = require "hump.class"
local Camera = require "hump.camera"
local SparseGrid = require "utilities.sparsegrid"
local Player = require "engine.player"

local Game = Class {}

function Game:init(project, playtest)
    self.project = project
    self.camera = Camera(128, 128, 2)
    self.playtest = playtest

    local tw, th = unpack(self.project.layers.surface.tileset.dimensions)

    self.actors = {}
    self.occupied = SparseGrid(tw, th)

    local function round(value, resolution)
        return math.floor(value * resolution) / resolution
    end

    local choice = {}

    for entity in pairs(self.project.layers.surface.entities) do
        local actor = Player(self, entity)
        self.actors[actor] = true

        table.insert(choice, actor)

        local cx, cy = entity.shape:coords { anchor={0.5, 0.5} } 
        local x, y = round(cx, 1/tw)+tw/2, round(cy, 1/th)+th/2
        entity:move_to { x=x, y=y, anchor={0.5, 0.5} }

        if actor.tags.player then
            self.player = actor
        end
    end

    if #choice == 0 then
        self:undo()
        MODE = EDITOR
        return
    end

    if not self.player then 
        self.player = choice[love.math.random(#choice)]
    end
end

function Game:update(dt)
    if not self.TEXT then
        for actor in pairs(self.actors) do
            if actor.active then
                self.occupied:set(nil, actor.tx, actor.ty)
                actor:update(dt)
                self.occupied:set(actor, actor.tx, actor.ty)
            end
        end
    end

    if self.player then
        self.camera.x, self.camera.y = self.player.entity.shape:coords { anchor = {0.5, 0.5} }
    end
end

function Game:destroy()
    
end

local font = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

local function box(message)
    love.graphics.setFont(font)

    local wrap = 512 - 16 * 8
    local w, h = font:getWrap(message, wrap)
    
    w, h = w + 16, (h + 2) * 16
    
    local sw, sh = love.window.getDimensions()
    local dx, dy = (sw - w) / 2, (sh - h) / 2

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setBlendMode("alpha")
    love.graphics.rectangle("fill", dx, dy, w, h)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf(message,
        dx + 16 + 1,
        dy + 16 + 4, wrap)
end

function Game:draw()
    self.camera:attach()
    self.project:draw(false, true)
    for actor in pairs(self.actors) do
        --if actor.active then actor:draw() end
    end
    self.camera:detach()

    if self.TEXT then
        box(self.TEXT)
    end
end

function Game:undo()
    for actor in pairs(self.actors) do
        actor.entity:move_to { x = actor.ox,  y = actor.oy, anchor={0.5, 0.5} }
        actor.entity.a = 0
        actor.entity.active = true
    end
end

function Game:mousepressed(x, y, button)
end

function Game:mousereleased(x, y, button)
end

function Game:keypressed(key, isrepeat)
    if not isrepeat then self.TEXT = nil end
end

function Game:keyreleased(key)
end

function Game:textinput(character)
end

return Game

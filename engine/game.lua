local Class = require "hump.class"
local Camera = require "hump.camera"
local SparseGrid = require "utilities.sparsegrid"
local Player = require "engine.player"

local Game = Class {}

function Game:init(project)
    self.project = project
    self.camera = Camera(128, 128, 2)

    self.actors = {}
    self.occupied = SparseGrid(32)

    local function round(value, resolution)
        return math.floor(value * resolution) / resolution
    end

    for entity in pairs(self.project.layers.surface.entities) do
        local actor = Player(self, entity)
        self.actors[actor] = true
        self.player = actor
        actor.speed = 0.75

        local x, y = round(entity.x, 1/32)+16, round(entity.y, 1/32)+16
        entity:moveTo(x, y)
    end

    if self.player then self.player.speed = 0.25 end
end

function Game:update(dt)
    if not self.TEXT then
        for actor in pairs(self.actors) do
            self.occupied:set(nil, actor.tx, actor.ty)
            actor:update(dt)
            self.occupied:set(true, actor.tx, actor.ty)
        end
    end

    if self.player then
        self.camera.x, self.camera.y = self.player.entity.x, self.player.entity.y
    end
end

local font = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

local function box(message)
    love.graphics.setFont(font)

    local wrap = 512 - 16 * 8
    local w, h = font:getWrap(message, wrap)
    
    w, h = w + 16, (h + 2) * 16
    
    local dx, dy = (512 - w) / 2, (512 - h) / 2

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
    self.camera:detach()

    if self.TEXT then
        box(self.TEXT)
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

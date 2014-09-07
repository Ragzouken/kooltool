local Class = require "hump.class"
local Camera = require "hump.camera"
local Player = require "engine.player"

local Game = Class {}

function Game:init(project)
    self.project = project
    self.camera = Camera(128, 128, 2)

    self.player = Player()

    self.actors = {}

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
    for actor in pairs(self.actors) do
        actor:update(dt)

        if actor ~= self.player then
            actor:rando()
        end
    end

    if self.player then
        self.camera.x, self.camera.y = self.player.entity.x, self.player.entity.y
    end
end

function Game:draw()
    self.camera:attach()
    self.project:draw(false, true)
    self.camera:detach()
end

function Game:mousepressed(x, y, button)
end

function Game:mousereleased(x, y, button)
end

function Game:keypressed(key, isrepeat)
end

function Game:keyreleased(key)
end

function Game:textinput(character)
end

return Game

local Player = require "player"

PLAYERS = nil
PLAYER = nil

function love.load()
    PLAYERS = {}

    for entity in pairs(PROJECT.layers.surface.entities) do
        local player = Player(entity)
        PLAYERS[player] = true
        PLAYER = player
        player.speed = 0.75
    end

    if PLAYER then PLAYER.speed = 0.25 end
end

function love.update(dt)
    for player in pairs(PLAYERS) do
        player:update(dt)

        if player ~= PLAYER then
            player:rando()
        end
    end

    if PLAYER then
        CAMERA.x, CAMERA.y = PLAYER.entity.x, PLAYER.entity.y
    end
end

function love.draw() 
    CAMERA:attach()
    PROJECT:draw()
    CAMERA:detach()
end

function love.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
end

function love.keypressed(key, isrepeat)
    if PLAYER then PLAYER:keypressed(key) end
end

function love.keyreleased(key)
end

function love.textinput(character)
end

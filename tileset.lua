local Class = require "hump.class"

local Tileset = Class {
    SIZE = 32,
    TILES = 16,
}

function Tileset:init()
    local ts = self.SIZE
    local w, h = ts * self.TILES, ts

    self.canvas = love.graphics.newCanvas(w, h)
    self.canvas:setFilter("nearest", "nearest")
    self.quads = {}
    self.tiles = 0

    for i=1,self.TILES do
        self.quads[i] = love.graphics.newQuad((i - 1) * self.SIZE, 0, ts, ts, w, h)
    end
end

function Tileset:draw()
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.rectangle("fill", 512-32-4-1, 4-1, 32+2, self.tiles*(32+1)+1)

    for i, quad in ipairs(self.quads) do
        local x, y = 512 - 32 - 4, 4 + (i - 1) * (32 + 1)

        love.graphics.draw(self.canvas, quad, x, y, 0, 1, 1)
    end
end

function Tileset:click(x, y)
    local ox = 512 - 32 - 4
    local oy = 4

    if x > ox and x < ox + 32 and y > 4 and y < 4+self.tiles*(32+1) then
        local dy = y - oy

        if dy % 33 <= 31 then
            return math.floor(dy / 33) + 1
        end
    end
end

function Tileset:add_tile()
    self.tiles = self.tiles + 1

    return self.tiles
end

function Tileset:clone(tile)
    local clone = self:add_tile()

    if tile then
        self:renderTo(clone, function()
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.draw(self.canvas, self.quads[tile], 0, 0)
        end)
    end

    return clone
end

function Tileset:renderTo(tile, action)
    love.graphics.push()
    love.graphics.translate((tile - 1) * self.SIZE, 0)

    love.graphics.setStencil(function()
        love.graphics.rectangle("fill", 0, 0, self.SIZE, self.SIZE)
    end)
    self.canvas:renderTo(action)
    love.graphics.setStencil()

    love.graphics.pop()
end

function Tileset:sample(tile, tx, ty)
    return {self.canvas:getPixel(tx + (tile - 1) * 32, ty)}
end

return Tileset

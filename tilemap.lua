local Class = require "hump.class"
local SparseGrid = require "sparsegrid"

local TileMap = Class {}

function TileMap.load(data)
    local map = TileMap(tileset)
    local x, y = 0, 0

    for row in string.gfind(data, "[^\n]+") do
        for index in string.gfind(row, "%d+") do
            local index = tonumber(index)

            if index > 0 then map:set(index, x, y) end

            x = x + 1
        end

        x = 0
        y = y + 1
    end

    return map
end

function TileMap:init(tileset)
    self.tileset = tileset
    self.batch = love.graphics.newSpriteBatch(tileset.canvas)

    self.tiles = SparseGrid()

    self.bounds = {0, 0, 0, 0}
end

function TileMap:update(dt)
end

function TileMap:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)
    
    love.graphics.draw(self.batch, 0, 0)
end

function TileMap:get(x, y)
    local tile = self.tiles:get(x, y)

    if tile then return unpack(tile) end
end

function TileMap:set(index, x, y)
    local quad = self.tileset.quads[index]
    local existing = self.tiles:get(x, y)
    local id

    if existing then
        id = existing[2]
        self.batch:set(id, quad, x * 32, y * 32)
    else
        id = self.batch:add(quad, x * 32, y * 32)
    end

    self.tiles:set({index, id}, x, y)

    self.bounds[1] = math.min(self.bounds[1], x)
    self.bounds[2] = math.min(self.bounds[2], y)
    self.bounds[3] = math.max(self.bounds[3], x)
    self.bounds[4] = math.max(self.bounds[4], y)
end

function TileMap:serialise()
    local rows = {}
    for y=self.bounds[2],self.bounds[4] do
        local row = {}
        
        for x=self.bounds[1],self.bounds[3] do
            row[#row+1] = self:get(x, y) or 0
        end

        rows[#rows+1] = table.concat(row, ",")
    end

    return table.concat(rows, "\n")
end

return TileMap

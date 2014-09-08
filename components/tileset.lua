local Class = require "hump.class"
local Brush = require "tools.brush"

local common = require "utilities.common"
local colour = require "utilities.colour"

local Tileset = Class {
    SIZE = 32,
    TILES = 16,
}

function Tileset:deserialise(data, saves)
    self.SIZE = data.tilesize

    local image = love.graphics.newImage(saves .. "/" .. data.file)
    self.canvas = common.canvasFromImage(image)

    self:add_tile(data.tiles)
end

function Tileset:serialise(saves)
    local file = "tileset.png"
    self.canvas:getImageData():encode(saves .. "/" .. file)

    return {
        file = file,
        tiles = self.tiles,
        tilesize = self.SIZE,
    }
end

function Tileset:init()
    local ts = self.SIZE
    local w, h = ts * 1, ts

    self.canvas = love.graphics.newCanvas(w, h)
    self.quads = {}
    self.tiles = 0

    self.snapshots = {}
end

function Tileset:snapshot(limit)
    local snapshot = love.graphics.newCanvas(self.canvas:getDimensions())

    --[[
    snapshot:renderTo(function()
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setBlendMode("premultiplied")
        love.graphics.draw(self.canvas, 0, 0)
    end)]]

    if #self.snapshots == limit then
        table.remove(self.snapshots, 1)
    end

    table.insert(self.snapshots, snapshot)

    return snapshot
end

function Tileset:undo()
    if #self.snapshots > 0 then
        print("UNDO")
        self.canvas = table.remove(self.snapshots)
    end
end

function Tileset:refresh()
    self.quads = {}

    local w, h = self.SIZE * self.tiles, self.SIZE

    self.canvas = common.resizeCanvas(self.canvas, w, h)
    for i=1,self.tiles do
        self.quads[i] = love.graphics.newQuad((i - 1) * self.SIZE, 0, 
            self.SIZE, self.SIZE, w, h)
    end
end

function Tileset:add_tile(count)
    self.tiles = self.tiles + (count or 1)

    self:refresh()

    return self.tiles
end

function Tileset:clone(tile)
    local clone = self:add_tile()

    if tile then
        if NOCANVAS then
            local data = self.canvas:getData()
            data:paste(data, (self.tiles - 1) * self.SIZE, 0, (tile - 1) * self.SIZE, 0, self.SIZE, self.SIZE)
            self.canvas.image = love.graphics.newImage(data)
        else
            local brush = Brush.image(self.canvas, self.quads[tile])
            self:applyBrush(clone, brush)
        end
    end

    return clone
end

function Tileset:applyBrush(index, brush, quad)
    love.graphics.setStencil(function()
        love.graphics.rectangle("fill", (index - 1) * self.SIZE, 0, self.SIZE, self.SIZE)
    end)
    
    brush:apply(self.canvas, quad, (index - 1) * self.SIZE, 0)
    
    love.graphics.setStencil()
end

function Tileset:sample(tile, tx, ty)
    return {self.canvas:getPixel(tx + (tile - 1) * 32, ty)}
end

return Tileset

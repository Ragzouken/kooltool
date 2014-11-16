local Class = require "hump.class"
local Brush = require "tools.brush"

local common = require "utilities.common"
local colour = require "utilities.colour"

local Tileset = Class {
    type = "Tileset",

    TILES = 16,
}

function Tileset:deserialise(resources, data)
    self.dimensions = data.dimensions
    self.tiles = data.tiles

    local image = love.graphics.newImage(resources:path(data.file))
    self.canvas = common.canvasFromImage(image)

    self:refresh()
end

function Tileset:serialise(resources)
    local full, file = resources:file(self, "tileset.png")
    self.canvas:getImageData():encode(full)

    return {
        file = file,
        tiles = self.tiles,
        dimensions = self.dimensions,
    }
end

function Tileset:init(tilesize)
    self.dimensions = tilesize or {32, 32}
    local w, h = unpack(self.dimensions)

    self.canvas = love.graphics.newCanvas(w, h)
    self.quads = {}
    self.tiles = 0

    self.snapshots = {}
end

function Tileset:finalise()
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

    local tw, th = unpack(self.dimensions)
    local w, h = tw * self.tiles, th

    self.canvas = common.resizeCanvas(self.canvas, w, h)
    for i=1,self.tiles do
        self.quads[i] = love.graphics.newQuad((i - 1) * tw, 0, 
                                              tw, th,
                                              w, h)
    end
end

function Tileset:add_tile(count)
    self.tiles = self.tiles + (count or 1)

    self:refresh()

    return self.tiles
end

function Tileset:clone(tile)
    local clone = self:add_tile()

    local tw, th = unpack(self.dimensions)

    if tile then
        if NOCANVAS then
            local data = self.canvas:getData()
            data:paste(data, (self.tiles - 1) * tw, 0, (tile - 1) * tw, 0, tw, th)
            self.canvas.image = love.graphics.newImage(data)
        else
            local brush = Brush.image(self.canvas, self.quads[tile])
            self:applyBrush(clone, brush)
        end
    end

    return clone
end

function Tileset:applyBrush(index, brush, quad, ox, oy)
    local tw, th = unpack(self.dimensions)
    local ox, oy = ox or 0, oy or 0

    love.graphics.setStencil(function()
        love.graphics.rectangle("fill", (index - 1) * tw, 0, tw, th)
    end)
    
    brush:apply(self.canvas, quad, (index - 1) * tw + ox, oy)
    
    love.graphics.setStencil()
end

function Tileset:sample(tile, tx, ty)
    local tw, th = unpack(self.dimensions)
    
    return {self.canvas:getPixel(tx + (tile - 1) * tw, ty)}
end

return Tileset

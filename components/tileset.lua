local Class = require "hump.class"
local Brush = require "tools.brush"
local Event = require "utilities.event"

local common = require "utilities.common"
local colour = require "utilities.colour" 

local Tileset = Class {
    type = "Tileset",

    BLOCK_SIZE = 1024,
}

function Tileset:deserialise(resources, data)
    self.dimensions = data.dimensions

    local image = love.graphics.newImage(resources:path(data.file))
    self.canvas = common.canvasFromImage(image)

    self.BLOCK_SIZE = image:getWidth()

    local tw, th = unpack(self.dimensions)

    if data.coords then
        for tile, coords in pairs(data.coords) do
            local x, y = unpack(coords)

            self.tiles = self.tiles + 1
            self.quads[tile] = love.graphics.newQuad(x, y, th, tw, image:getDimensions())
        end
    else
        local tpr = math.floor(image:getWidth() / tw)
        local tpc = math.floor(image:getHeight() / th)

        local y = 0
        --for y=0,tpc-1 do
            for x=0,tpr-1 do
                local tile= y * tpr + x + 1
                self.tiles = self.tiles + 1
                self.quads[tile] = love.graphics.newQuad(x * tw, y * th, th, tw, image:getDimensions())
            end
        --end
    end

    self.changed:fire(self)
end

function Tileset:serialise(resources)
    local full, file = resources:file(self, "tileset.png")
    self.canvas:getImageData():encode(full)

    local coords = {}

    for tile, quad in pairs(self.quads) do
        coords[tile] = { quad:getViewport() }
    end

    return {
        file = file,
        dimensions = self.dimensions,
        coords = coords,
    }
end

function Tileset:init(tilesize)
    self.dimensions = tilesize or {32, 32}

    self.canvas = love.graphics.newCanvas(self.BLOCK_SIZE, self.BLOCK_SIZE)
    self.quads = {}
    self.tiles = 0

    self.snapshots = {}

    self.changed = Event()
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

function Tileset:add_tile()
    self.tiles = self.tiles + 1

    local tw, th = unpack(self.dimensions)

    local tpr = math.floor(self.canvas:getWidth() / tw)
    local tpc = math.floor(self.canvas:getHeight() / th)

    local gx = (self.tiles - 1) % tpr
    local gy = math.floor((self.tiles - 1) / tpr)

    self.quads[self.tiles] = love.graphics.newQuad(gx * tw, gy * th, tw, th, self.canvas:getDimensions())

    self.changed:fire(self)

    return self.tiles
end

function Tileset:clone(tile)
    local clone = self:add_tile()

    local tw, th = unpack(self.dimensions)
    local sx, sy = self.quads[tile]:getViewport()
    local cx, cy = self.quads[clone]:getViewport()

    if tile then
        if NOCANVAS then
            local data = self.canvas:getData()
            data:paste(data, cx, cy, sx, sy, tw, th)
            self.canvas.image = love.graphics.newImage(data)
        else
            local brush = Brush.image(self.canvas, self.quads[tile])
            self:applyBrush(clone, brush)
        end
    end

    self:refresh()

    return clone
end

function Tileset:applyBrush(index, brush, quad, ox, oy)
    local tw, th = unpack(self.dimensions)
    local ox, oy = ox or 0, oy or 0

    local x, y, w, h = self.quads[index]:getViewport()

    love.graphics.setStencil(function()
        love.graphics.rectangle("fill", x, y, w, h)
    end)
    
    brush:apply(self.canvas, quad, x + ox, y + oy)
    
    love.graphics.setStencil()
end

function Tileset:sample(tile, tx, ty)
    local sx, sy = self.quads[index]:getViewport()

    return {self.canvas:getPixel(tx + sx, ty + sy)}
end

return Tileset

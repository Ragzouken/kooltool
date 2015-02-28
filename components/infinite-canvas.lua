local Class = require "hump.class"
local SparseGrid = require "utilities.sparsegrid"

local common = require "utilities.common"

local InfiniteCanvas = Class {
    type = "InfiniteCanvas",

    blocksize = 1024,
}

function InfiniteCanvas:serialise(resources)
    local data = {}

    data.blocks = self.blocks:serialise(function(block, x, y)
        local full, file = resources:file(self, x .. "," .. y .. ".png")

        if self.dirty:get(x, y) then
            block:getImageData():encode(full)
        end

        return file
    end)

    self.dirty:clear()

    return data
end

function InfiniteCanvas:deserialise(resources, data)
    self.blocks:deserialise(function(path, x, y)
        local image = love.graphics.newImage(resources:path(path))
        local block = common.canvasFromImage(image)

        return block
    end, data.blocks)

    self.dirty:clear()
end

function InfiniteCanvas:finalise()
end

function InfiniteCanvas:init(blocksize)
    self.blocks = SparseGrid(blocksize or self.blocksize)
    self.dirty = SparseGrid()
end

function InfiniteCanvas:draw()
    local width, height = unpack(self.blocks.cell_dimensions)

    for block, x, y in self.blocks:items() do
        love.graphics.draw(block, x * width, y * height)
    end
end

function InfiniteCanvas:brush(x, y, brush)
    local gx, gy, px, py = self.blocks:gridCoords(math.floor(x), math.floor(y))

    local bw, bh = brush:getDimensions()
    local width, height = unpack(self.blocks.cell_dimensions)

    -- how many grid cells does the brush span?
    local gw = math.ceil((bw + px) / width)
    local gh = math.ceil((bh + py) / height)

    local quad = love.graphics.newQuad(0, 0, width, height, bw, bh)

    for y=0,gh-1 do
        for x=0,gw-1 do
            local block = self.blocks:get(gx + x, gy + y)
            
            quad:setViewport(-px + x * width, -py + y * height, width, height)

            if not block then
                block = love.graphics.newCanvas(width, height)
                self.blocks:set(block, gx + x, gy + y)
            end

            brush:apply(block, quad, 0, 0)

            self.dirty:set(true, gx + x, gy + y)
        end
    end
end

function InfiniteCanvas:sample(x, y)
    local gx, gy, px, py = self.blocks:gridCoords(x, y)
    local block = self.blocks:get(gx, gy)

    return block and { block:getPixel(math.floor(px), math.floor(py)) }
end

return InfiniteCanvas

local Class = require "hump.class"

local SparseGrid = Class {}

function SparseGrid:init(cell_width, cell_height)
    self.grid = {}
    self.cell_width = cell_width or 0
    self.cell_height = cell_height or cell_width or 0
end

function SparseGrid:clear()
    self.grid = {}
end

function SparseGrid:set(item, x, y, z)
    local layer = self.grid[z or 1] or {}
    local row = layer[y] or {}

    self.grid[z or 1] = layer
    layer[y] = row
    row[x] = item
end

function SparseGrid:get(x, y, z)
    local layer = self.grid[z or 1] or {}
    local row = layer[y] or {}

    return row[x]
end

function SparseGrid:remove(x, y, z)
    local item = self:get(x, y, z)

    self:set(nil, x, y, z)

    return item
end

function SparseGrid:items(...)
    return coroutine.wrap(function()
        for z, layer in pairs(self.grid) do
            for y, row in pairs(layer) do
                for x, item in pairs(row) do
                    coroutine.yield(item, x, y, z)
                end
            end
        end
    end)
end

function SparseGrid:gridCoords(x, y)
    local gx, gy = math.floor(x / self.cell_width), math.floor(y / self.cell_height)
    local ox, oy = math.floor(x % self.cell_width), math.floor(y % self.cell_height)

    return gx, gy, ox, oy
end

return SparseGrid

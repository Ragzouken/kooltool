local Class = require "hump.class"

local SparseGrid = Class {}

function SparseGrid:init(cell_width, cell_height)
    self.cell_width = cell_width or 0
    self.cell_height = cell_height or cell_width or 0

    self:clear()
end

function SparseGrid:SetCellSize(cell_width, cell_height)
    self.cell_width = cell_width
    self.cell_height = cell_height or cell_width
end

function SparseGrid:clear()
    self.grid = {}
    self.bounds = {}
end

function SparseGrid:set(item, x, y, z)
    local layer = self.grid[z or 1] or {}
    local row = layer[y] or {}

    self.grid[z or 1] = layer
    layer[y] = row
    row[x] = item

    self.bounds.x1 = self.bounds.x1 and math.min(self.bounds.x1, x) or x
    self.bounds.y1 = self.bounds.y1 and math.min(self.bounds.y1, y) or y
    self.bounds.x2 = self.bounds.x2 and math.max(self.bounds.x2, x) or x
    self.bounds.y2 = self.bounds.y2 and math.max(self.bounds.y2, y) or y
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

function SparseGrid:items()
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

function SparseGrid:rectangle()
    return coroutine.wrap(function()
        for y=self.bounds.y1,self.bounds.y2 do
            for x=self.bounds.x1,self.bounds.x2 do
                coroutine.yield(self:get(x, y) or false, x, y)
            end
        end
    end)
end

function SparseGrid:gridCoords(x, y)
    local gx, gy = math.floor(x / self.cell_width), math.floor(y / self.cell_height)
    local ox, oy = math.floor(x % self.cell_width), math.floor(y % self.cell_height)

    return gx, gy, ox, oy
end

function SparseGrid:regions()
    local touched = SparseGrid()
    local regions = {}
    local neighbours = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}

    for item, x, y in self:items() do
        if not touched:get(x, y) then
            local region = SparseGrid()
            table.insert(regions, region)

            local function flood(x, y)
                local item = self:get(x, y)

                if not touched:get(x, y) and item then
                    touched:set(true, x, y)
                    region:set(item, x, y)

                    for i, neighbour in ipairs(neighbours) do
                        local dx, dy = unpack(neighbour)

                        flood(x+dx, y+dy)
                    end
                end
            end

            flood(x, y)
        end
    end

    return regions
end

return SparseGrid

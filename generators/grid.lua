local SparseGrid = require "utilities.sparsegrid"

local grid = {}

function grid.dungeon()
    local dungeon = SparseGrid()

    for y=0,7 do
        for x=0,7 do
            dungeon:set(love.math.random(2), x, y)
        end
    end

    return dungeon
end

return grid

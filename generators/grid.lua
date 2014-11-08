local SparseGrid = require "utilities.sparsegrid"
local common = require "generators.common"

local grid = {}

local function outline(grid, outline)
    local actions = {}

    for index, x, y in grid:items() do
        for dx=-1,1 do
            for dy=-1,1 do
                if not grid:get(x+dx, y+dy) then
                    table.insert(actions, function() grid:set(outline, x+dx, y+dy) end)
                end
            end
        end
    end

    for i, action in ipairs(actions) do
        action()
    end
end

function grid.dungeon()
    local dungeon = SparseGrid()

    local agents = {}

    for i=1,math.random(3,7) do
        agents[common.Turtle(4, 4, math.random(3))] = true
    end

    
    for agent in pairs(agents) do
        for i=1,math.random(5, 7) do
            agent:spin()
            
            if math.random() > 0.125 then
                for i=1,math.random(4, 7) do
                    dungeon:set(1, agent.x, agent.y)
                    agent:forward()
                end
            else
                for y=-math.random(2),math.random(2) do
                    for x=-math.random(2),math.random(2) do
                        dungeon:set(1, x+agent.x, y+agent.y)
                    end
                end
            end
        end
    end

    outline(dungeon, 2)

    return dungeon
end

return grid

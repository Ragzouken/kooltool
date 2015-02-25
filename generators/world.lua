local world = {}

function world.default(project)
    local WorldLayer = require "layers.world"
    local generators = require "generators"
    
    local layer = WorldLayer(project)

    layer.tilemap:set_tileset(generators.tileset.flat(project))
    
    for tile, x, y in generators.grid.dungeon():items() do
        layer.tilemap:set(tile, x, y)
    end

    --layer.wall_index = {[2] = true}

    return layer
end

return world

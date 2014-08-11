local SurfaceLayer = require "layers.surface"

local surface = {}

function surface.default(project)
    local generators = require "generators"
    
    local layer = SurfaceLayer(project)

    layer.tileset = generators.tileset.flat(project)
    
    for tile, x, y in generators.grid.dungeon():items() do
        layer:setTile(tile, x, y)
    end

    return layer
end

return surface

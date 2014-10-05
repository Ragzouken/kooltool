local SurfaceLayer = require "layers.surface"

local surface = {}

function surface.default(project, tilesize)
    local generators = require "generators"
    
    local layer = SurfaceLayer(project, tilesize)

    layer:SetTileset(generators.tileset.flat(project, tilesize))
    
    for tile, x, y in generators.grid.dungeon():items() do
        layer:setTile(tile, x, y)
    end

    return layer
end

return surface

local Class = require "hump.class"
local SparseGrid = require "utilities.sparsegrid"

local Region = Class {
    type = "Region",
}

function Region:serialise(resources)
    local data = {}

    data.layers = {}

    for layer, grid in pairs(self.layers) do
        table.insert(data.layers, {layer = resources:reference(layer), 
                                   grid = grid:serialise()})
    end

    data.defaults = self.defaults
    data.colour = self.colour

    return data
end

function Region:deserialise(resources, data)
    for i, pair in ipairs(data.layers) do
        local grid = SparseGrid()
        grid:deserialise(nil, pair.grid)

        local layer = resources:resource(pair.layer)

        self.layers[layer] = grid 
    end

    self.defaults = data.defaults
    self.colour = data.colour
end

function Region:finalise(resources, data)
end

function Region:init(project)
    self.project = project

    self.layers = {}
    self.defaults = {}
    self.colour = {255, 0, 255, 255}
end

function Region:layer(layer)
    if not self.layers[layer] then
        self.layers[layer] = SparseGrid(unpack(self.project.gridsize))
    end

    return self.layers[layer]
end

function Region:include(layer, x, y)
    return self:layer(layer):set(true, x, y)
end

function Region:exclude(layer, x, y)
    return self:layer(layer):set(nil, x, y)
end

function Region:includes(layer, x, y)
    return self:layer(layer):get(x, y) --or self.defaults[self.tilemap:get(x, y)]
end

function Region:default(tile, state)
    self.defaults[tile] = state
end

function Region:items(layer)
    return self:layer(layer):items()
end

return Region

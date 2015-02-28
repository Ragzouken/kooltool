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
    data.project = resources:reference(self.project)

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
    self.project = resources:resource(data.project)
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
    local tile = layer:tile():get(x, y)

    return self:layer(layer):get(x, y) or self.defaults[tile]
end

function Region:default_include(layer, x, y)
    local tile = layer:tile():get(x, y)
    local change = not self.defaults[tile]

    if not tile then return false end

    self.defaults[tile] = true

    return change
end

function Region:default_exclude(layer, x, y)
    local tile = layer:tile():get(x, y)
    local change = self.defaults[tile]

    self.defaults[tile] = nil

    return change
end

function Region:items(layer)
    return self:layer(layer):items()
end

return Region

local Class = require "hump.class"
local Layer = require "layers.layer"
local EditHandle = require "tools.edit-handle"

local SparseGrid = require "utilities.sparsegrid"
local InfiniteCanvas = require "components.infinite-canvas"
local TileMap = require "components.tilemap"

local WorldLayer = Class {
    __includes = Layer,
    type = "WorldLayer",
    name = "kooltool world layer",

    actions = { "draw", "tile", "entity" },

    clone_sound = love.audio.newSource("sounds/clone.wav"),
}

function WorldLayer:serialise(resources)
    local data = {}

    data.project = resources:reference(self.project)
    data.drawing = resources:reference(self.drawing)
    data.tilemap = resources:reference(self.tilemap)

    data.entities = {}

    for entity in pairs(self.entities) do
        table.insert(data.entities, resources:reference(entity))
    end

    return data
end

function WorldLayer:deserialise(resources, data)
    self.project = resources:resource(data.project)
    self.drawing = resources:resource(data.drawing)
    self.tilemap = resources:resource(data.tilemap)

    local handle = self:entity()

    for i, entity in ipairs(data.entities) do
        handle:add(resources:resource(entity))
    end
end

function WorldLayer:finalise(resources)
end

function WorldLayer:init(project)
    Layer.init(self, project)

    self.project = project
    self.drawing = InfiniteCanvas()
    self.tilemap = TileMap()
    self.entities = {}
end

function WorldLayer:draw()
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode("premultiplied")

    -- stencil with tiles

    self.drawing:draw()

    self.tilemap:draw()
end

function WorldLayer:tile(x, y)
    local handle = EditHandle()
    local tilemap = self.tilemap

    function handle:set(tile, x, y)
        return tilemap:set(tile, x, y)
    end

    function handle:get(x, y)
        return tilemap:get(x, y)
    end

    function handle:grid_coords(x, y)
        return tilemap.tiledata:grid_coords(x, y)
    end

    return handle
end

function WorldLayer:pixel(x, y)
    local handle = EditHandle()

    local gx, gy = self.tilemap.tiledata:grid_coords(x, y)

    if self.tilemap:get(gx, gy) then
        handle.cloned = {}

        local tilemap = self.tilemap

        function handle:brush(brush, x, y)
            tilemap:brush(brush, x, y, self.options)
        end

        function handle:sample(x, y)
            return tilemap:sample(x, y)
        end
    else
        local drawing = self.drawing

        function handle:brush(brush, x, y)
            drawing:brush(x, y, brush)
        end

        function handle:sample(x, y)
            return drawing:sample(x, y)
        end
    end

    return handle
end

function WorldLayer:entity(x, y)
    local handle = EditHandle()

    local layer = self

    function handle:add(entity)
        entity.layer = layer
        layer.entities[entity] = true
        layer:add(entity)
    end

    return handle
end

return WorldLayer

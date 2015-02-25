local Class = require "hump.class"
local Collider = require "collider"
local SparseGrid = require "utilities.sparsegrid"
local InfiniteCanvas = require "components.infinite-canvas"
local Notebox = require "components.notebox"
local Layer = require "layers.layer"

local colour = require "utilities.colour"
local common = require "utilities.common"

local AnnotationLayer = Class {
    __includes = Layer,
    type = "AnnotationLayer",
    name = "kooltool annotation layer",

    actions = { "mark", "note", },
    tags = { "editor", "annotation", },

    BLOCK_SIZE = 1024,
}

function AnnotationLayer:serialise(resources)
    local noteboxes = {}

    for notebox in pairs(self.children) do
        if notebox.type == "Notebox" then
            table.insert(noteboxes, notebox:serialise())
        end
    end

    return {
        notes = noteboxes,
        canvas = resources:reference(self.canvas),
    }
end

function AnnotationLayer:deserialise(resources, data)
    for i, data in pairs(data.notes) do
        local notebox = Notebox(self)
        notebox:deserialise(resources, data)
        self:add(notebox)
    end

    self.canvas = resources:resource(data.canvas)
end

function AnnotationLayer:init()
    Layer.init(self)

    self.noteboxes = {}

    self.canvas = InfiniteCanvas(self.BLOCK_SIZE)
end

function AnnotationLayer:finalise()
    self.canvas:finalise()
end

function AnnotationLayer:draw(params)
    love.graphics.setBlendMode("premultiplied")
    
    love.graphics.setColor(colour.cursor(0))

    self.canvas:draw()

    love.graphics.setColor(255, 255, 255, 255)
end

function AnnotationLayer:applyBrush(bx, by, brush)
    self.canvas:brush(bx, by, brush)
end

return AnnotationLayer

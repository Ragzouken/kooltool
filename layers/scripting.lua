local Class = require "hump.class"
local Collider = require "collider"
local Layer = require "layers.layer"
local AnnotationLayer = require "layers.annotation"

local colour = require "utilities.colour"

local ScriptingLayer = Class {
    __includes = Layer,

    padding = 8,
}

function ScriptingLayer:serialise(saves)
    local nodes = {}



    return {
        nodes = nodes,
    }
end

function ScriptingLayer:deserialise(data, saves)
end

function ScriptingLayer:init(project)
    Layer.init(self, project)

    self.collider = Collider()

    self.annotations = AnnotationLayer(project)
    self.nodes = {}
end

function ScriptingLayer:draw()
    local radius = 0

    for node in pairs(self.nodes) do
        local d = math.sqrt(node.x * node.x + node.y * node.y)
        radius = math.max(radius, d+node.radius)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(colour.cursor(0, 64))
    love.graphics.circle("fill", 0, 0, radius+self.padding)

    for node in pairs(self.nodes) do
        node:draw()
    end

    self.annotations:draw()
end

function ScriptingLayer:addNode(node)
    self.nodes[node] = true
    self.collider:addShape(node.shape)
end

return ScriptingLayer

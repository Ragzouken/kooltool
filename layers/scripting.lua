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

    self.annotations = AnnotationLayer(project)
    self.nodes = {}
end

function ScriptingLayer:addNode(node)
    self.nodes[node] = true
end

return ScriptingLayer

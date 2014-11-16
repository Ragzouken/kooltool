local Class = require "hump.class"
local Collider = require "collider"
local Layer = require "layers.layer"
local AnnotationLayer = require "layers.annotation"

local common = require "utilities.common"
local colour = require "utilities.colour"

local ScriptingLayer = Class {
    __includes = Layer,
    type = "ScriptingLayer",

    padding = 8,
    brain = common.loadCanvas("images/brain.png"),
}

function ScriptingLayer:serialise(resources)
end

function ScriptingLayer:deserialise(resources, data)
end

function ScriptingLayer:init()
    Layer.init(self)

    self.annotations = AnnotationLayer()
    self.nodes = {}
end

function ScriptingLayer:draw()
    Layer.draw_children(self)

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(self.brain, 0, 0)
end

return ScriptingLayer

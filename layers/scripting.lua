local Class = require "hump.class"
local Collider = require "collider"
local Panel = require "interface.elements.panel"
local AnnotationLayer = require "layers.annotation"
local Notebox = require "components.notebox"

local shapes = require "interface.elements.shapes"
local common = require "utilities.common"
local colour = require "utilities.colour"

local ScriptingLayer = Class {
    __includes = Panel,
    type = "ScriptingLayer",

    padding = 8,
    brain = common.loadCanvas("images/brain.png"),

    actions = { "dismiss", },
    tags = { "editor", },
}

function ScriptingLayer:serialise(resources)
    local data = {}

    data.annotation = resources:reference(self.annotation)

    return data
end

function ScriptingLayer:deserialise(resources, data)
    self.annotation = resources:resource(data.annotation)
    self:add(self.annotation)
end

function ScriptingLayer:blank()
    self.annotation = AnnotationLayer()
    self:add(self.annotation)
end

function ScriptingLayer:init()
    Panel.init(self)

    self.border = Panel {
        shape = shapes.Rectangle { },

        colours = {line = {255, 255, 255, 255},
                   fill = {  0,   0,   0,  64}},
    }

    self:add(self.border, 5)
end

function ScriptingLayer:finalise()
end

function ScriptingLayer:update(dt)
    Panel.update(self, dt)

    self.border.shape:set(0, 0, 0, 0)
    self.border.shape:include(self.parent.shape)

    local rect = shapes.Rectangle { }
    
    for notebox in pairs(self.annotation.children) do
        local x, y, w, h = notebox.shape:get()
        rect:set(x + notebox.x, y + notebox.y, w, h)

        self.border.shape:include(rect)
    end

    self.annotation.shape = self.border.shape

    self.border.shape.padding = 2.5
    self.border.colours.fill = {colour.cursor(0, 64)}

    self.annotation.clip = true

    self.shape = self.border.shape
end

return ScriptingLayer

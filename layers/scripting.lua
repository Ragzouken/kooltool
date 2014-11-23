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
        shape = shapes.Rectangle { x =  0, y =  0,
                                   w = 50, h = 50 },

        colours = {stroke = {255, 255, 255, 255},
                   fill   = {  0,   0,   0,  32}},
    }

    self:add(self.border)
end

function ScriptingLayer:finalise()
end

function ScriptingLayer:update(dt)
    Panel.update(self, dt)

    local dx, dy = unpack(self.parent.sprite.pivot)

    local size = {0, 0,
                  self.parent.shape.w, self.parent.shape.h}

    for notebox in pairs(self.annotation.noteboxes) do
        local shape = notebox.shape
        local rect = {shape.x, shape.y, shape.w, shape.h}

        size = common.expandRectangle(size, rect)
    end

    local x, y, w, h = unpack(size)
    self.border.shape.x, self.border.shape.y, self.border.shape.w, self.border.shape.h = x, y, w, h

    self.annotation.shape = self.border.shape
end

--[[
function ScriptingLayer:draw()
    Panel.draw_children(self)

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(self.brain, 0, 0)
end
]]

return ScriptingLayer

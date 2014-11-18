local Class = require "hump.class"
local Camera = require "hump.camera"
local Panel = require "interface.elements.panel"
local Sprite = require "components.sprite"
local ScriptLayer = require "layers.scripting"

local common = require "utilities.common"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local generators = require "generators"

local Entity = Class {
    __includes = Panel,
    name = "Generic Entity",
    type = "Entity",

    actions = {"drag", "draw", "remove", "tooltip"},
    tooltip = "character",
}

function Entity:deserialise(resources, data)
    self.sprite = resources:resource(data.sprite)
end

function Entity:serialise(resources)
    local x, y = self.shape:coords{ pivot = self.sprite.pivot }

    return {
        x = x, y = y,
        sprite = resources:reference(self.sprite),
    }
end

function Entity:init()
    Panel.init(self, { 
        shape = shapes.Rectangle { x = 0, y = 0, 
                                   w = 0, h = 0 },
    })
end

function Entity:finalise(resources, data)
    self.shape.w, self.shape.h = self.sprite.canvas:getDimensions()
    self:move_to { x = data.x, y = data.y, pivot = self.sprite.pivot }

    self.sprite.resized:add(function(...) self:resized(...) end)
end

function Entity:blank(x, y)
    self.sprite = generators.sprite.mess(self.layer.tileset.dimensions, PALETTE)
    self.shape.w, self.shape.h = self.sprite.canvas:getDimensions()
    self:move_to { x = x, y = y, pivot = self.sprite.pivot }

    self.sprite.resized:add(function(...) self:resized(...) end)

    self.script = ScriptLayer()
    --self:add(self.script)
end

function Entity:draw()
    love.graphics.push()
    love.graphics.translate(self.shape.x, self.shape.y)

    self.sprite:draw(0, 0, self.a)

    love.graphics.pop()

    self:draw_children()
end

function Entity:border()
    local px, py = unpack(self.sprite.pivot)
    local w, h = self.sprite.canvas:getDimensions()

    local x, y = self.shape.x, self.shape.y
    local w, h = self.shape.w, self.shape.h

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(colour.cursor(0))
    love.graphics.rectangle("line", x - 0.5,
                                    y - 0.5, 
                                    w+1, h+1)
end

function Entity:remove()
    if self.layer then self.layer:removeEntity(self) end
end

function Entity:applyBrush(...)
    return self.sprite:applyBrush(...)
end

function Entity:sample(...)
    return self.sprite:sample(...)
end

function Entity:resized(params)
    self.shape:grow(params)
end

return Entity

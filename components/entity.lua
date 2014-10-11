local Class = require "hump.class"
local Camera = require "hump.camera"
local Panel = require "interface.elements.panel"
local Sprite = require "components.sprite"
local ScriptLayer = require "layers.scripting"

local ScriptNode = require "components.scripting.scriptnode"
local BumpNode = require "components.scripting.bumpnode"
local DialogueNode = require "components.scripting.dialoguenode"

local common = require "utilities.common"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"

local Entity = Class {
    __includes = Panel,
    name = "Generic Entity",
}

function Entity:deserialise(data, saves)
    self.sprite = self.layer.sprites_index[data.sprite]

    self.shape.w, self.shape.h = self.sprite.canvas:getDimensions()
    self:move_to { x = data.x, y = data.y, pivot = self.sprite.pivot }

    self.sprite.resized:add(function(...) self:resized(...) end)
end

function Entity:serialise(saves)
    return {
        x = self.shape.x, y = self.shape.y,
        sprite = self.layer.sprites[self.sprite],
    }
end

function Entity:init(layer)
    self.layer = layer

    Panel.init(self, { 
        shape = shapes.Rectangle { x = 0, y = 0, 
                                   w = 0, h = 0 },
        actions = {"drag", "draw"},
    })
end

function Entity:blank(x, y)
    self.sprite = self.layer:newSprite()
    self.shape.w, self.shape.h = self.sprite.canvas:getDimensions()
    self:move_to { x = x, y = y, pivot = self.sprite.pivot }
end

function Entity:draw()
    love.graphics.push()
    love.graphics.translate(self.shape.x, self.shape.y)

    self.sprite:draw(0, 0)

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

-- TODO: this is bork
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

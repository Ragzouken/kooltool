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
    self.shape.x, self.shape.y = data.x, data.y
    self.sprite = self.layer.sprites_index[data.sprite]

    self.sprite.entity = self
    self:add(self.sprite)

    self.sprite:refresh()
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
        actions = {"drag"}, 
        shape = shapes.Rectangle { x = 0, y = 0, 
                                   w = 0, h = 0 },
    })
end

function Entity:blank(x, y)
    self.shape.x, self.shape.y = x, y
    self.sprite = self.layer:newSprite()
    
    self.sprite.entity = self
    self:add(self.sprite)

    self.sprite:refresh()
    self:move_to { x = x, y = y, anchor = {0.5, 0.5} }
end

function Entity:border()
    local px, py = unpack(self.sprite.pivot)
    local w, h = self.sprite.canvas:getDimensions()

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(colour.cursor(0))
    love.graphics.rectangle("line", self.shape.x - px - 0.5,
                                    self.shape.y - py - 0.5, 
                                    w+1, h+1)
end

return Entity

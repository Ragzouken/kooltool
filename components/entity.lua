local Class = require "hump.class"
local Camera = require "hump.camera"
local Sprite = require "components.sprite"
local ScriptLayer = require "layers.scripting"

local ScriptNode = require "components.scripting.scriptnode"
local BumpNode = require "components.scripting.bumpnode"
local DialogueNode = require "components.scripting.dialoguenode"

local common = require "utilities.common"
local shapes = require "collider.shapes"
local colour = require "utilities.colour"

local Entity = Class {}

function Entity:deserialise(data, saves)
    self.x, self.y = data.x, data.y
    self.sprite = self.layer.sprites_index[data.sprite]
    self:refresh()
end

function Entity:serialise(saves)
    return {
        x = self.x, y = self.y,
        sprite = self.layer.sprites[self.sprite],
    }
end

function Entity:init(layer, x, y)
    self.layer = layer

    self.script = ScriptLayer()
    self.camera = Camera()
end

function Entity:blank(x, y)
    self.x, self.y = x, y
    self.sprite = Sprite()
    self.layer:addSprite(self.sprite)
    self.script:addNode(DialogueNode(self.script, 0, 40))
    self:refresh()
end

function Entity:draw()
    self.camera:attach()
    self.script:draw()
    self.camera:detach()

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode("premultiplied")
    self.sprite:draw(self.x, self.y)
end

function Entity:border()
    local px, py = unpack(self.sprite.pivot)
    local w, h = self.sprite.canvas:getDimensions()

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(colour.cursor(0))
    love.graphics.rectangle("line", self.x - px - 0.5, self.y - py - 0.5, w+1, h+1)
end

function Entity:move(dx, dy)
    self.shape:move(dx, dy)
    self.x, self.y = self.x + dx, self.y + dy
end

function Entity:moveTo(x, y)
    x, y = math.floor(x), math.floor(y)
    local px, py = unpack(self.sprite.pivot)
    local w, h = unpack(self.sprite.size)

    local cx, cy = w/2, h/2
    local dx, dy = cx - px, cy - py

    self.shape:moveTo(x + dx, y + dy)
    self.x, self.y = x, y

    self.camera:lookAt(-self.x+256, -self.y+256)
end

function Entity:applyBrush(bx, by, brush, lock, cloning)
    if cloning then
        self.sprite = Sprite(self.sprite)
        self.layer:addSprite(self.sprite)
    end

    self.sprite:applyBrush(bx - self.x, by - self.y, brush, lock)

    self:refresh()
end

function Entity:sample(x, y)
    x, y = x - self.x, y - self.y

    return self.sprite:sample(x, y)
end

function Entity:refresh()
    local w, h = unpack(self.sprite.size)

    local shape = shapes.newPolygonShape(0, 0, w, 0, w, h, 0, h)
    shape.entity = self
    if self.shape then self.layer:swapShapes(self.shape, shape) end
    self.shape = shape

    self:moveTo(self.x, self.y)
end

return Entity

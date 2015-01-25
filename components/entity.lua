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

    actions = {"drag", "draw", "remove", "tooltip", "script"},
    tooltip = "character",
    colours = Panel.COLOURS.transparent,
}

function Entity:deserialise(resources, data)
    self:move_to { x = data.x, y = data.y }
    self.sprite = resources:resource(data.sprite)
    self.script = resources:resource(data.script)

    if not self.script then self.script = ScriptLayer() self.script:blank() end

    self:add(self.script)
    self.script.active = false
end

function Entity:serialise(resources)
    return {
        x = self.x, y = self.y,
        sprite = resources:reference(self.sprite),
        script = resources:reference(self.script),
    }
end

function Entity:init()
    Panel.init(self, { shape = shapes.Rectangle{} })
end

function Entity:finalise(resources, data)
    local px, py = unpack(self.sprite.pivot)

    self.shape:set(-px, -py, self.sprite.canvas:getDimensions())

    self.sprite.resized:add(function(...) self:resized(...) end)
end

function Entity:blank(x, y)
    self.sprite = generators.sprite.mess(self.layer.tileset.dimensions, PALETTE)
    
    local px, py = unpack(self.sprite.pivot)

    self.shape:set(-px, -py, self.sprite.canvas:getDimensions())
    
    self:move_to { x = x, y = y }

    self.sprite.resized:add(function(...) self:resized(...) end)

    self.script = ScriptLayer()
    self.script:blank()
    self:add(self.script)
end

function Entity:draw(params)
    self.sprite:draw(0, 0, self.a)

    if self.border then
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(colour.cursor(0))
        self.shape:draw("line", 0.5)

        self.border = false

        --print(self.shape.x, self.shape.y, self.shape.w, self.shape.h)
    end
end

function Entity:remove()
    if self.layer then self.layer:removeEntity(self) end
end

function Entity:applyBrush(ox, oy, ...)
    ox = ox - self.shape.x
    oy = oy - self.shape.y

    return self.sprite:applyBrush(ox, oy, ...)
end

function Entity:sample(...)
    return self.sprite:sample(...)
end

function Entity:resized(params)
    self.shape:grow(params)
end

return Entity

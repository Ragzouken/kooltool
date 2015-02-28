local Class = require "hump.class"
local Camera = require "hump.camera"
local Panel = require "interface.elements.panel"
local Sprite = require "components.sprite"
local ScriptLayer = require "layers.scripting"
local EditHandle = require "tools.edit-handle"

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

function Entity:blank(x, y, sprite)
    self.sprite = sprite or generators.sprite.mess(self.layer.project.gridsize, self.layer.project.palette)
    
    local px, py = unpack(self.sprite.pivot)

    self.shape:set(-px, -py, self.sprite.canvas:getDimensions())
    
    self:move_to { x = x, y = y }

    self.sprite.resized:add(function(...) self:resized(...) end)

    self.script = ScriptLayer()
    self.script:blank()
    self.script.active = false
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

function Entity:move_to(params)
    if self.layer and MODE == EDITOR then
        local tw, th = unpack(self.layer.project.gridsize)
        params.x = (math.floor(params.x / tw) + 0.5) * tw
        params.y = (math.floor(params.y / th) + 0.5) * th
    end

    Panel.move_to(self, params)
end

function Entity:remove()
    if self.layer then self.layer:entity():remove(self) end
end

function Entity:pixel()
    local handle = EditHandle()

    local entity = self

    function handle:brush(brush, ox, oy)
        ox = ox - entity.shape.x
        oy = oy - entity.shape.y

        if self.options.cloning and not self.options.cloning[entity] then
            local clone = Sprite()
            clone.canvas = common.canvasFromImage(entity.sprite.canvas)
            clone.pivot = {unpack(entity.sprite.pivot)}

            entity.layer.project:add_sprite(clone)
            MODE.toolbox.panels.sprites:refresh()

            entity.sprite = clone

            self.options.cloning[entity] = true
        end

        return entity.sprite:applyBrush(ox, oy, brush, self.options.lock)
    end

    return handle
end

function Entity:sample(...)
    return self.sprite:sample(...)
end

function Entity:resized(params)
    self.shape:grow(params)
end

return Entity

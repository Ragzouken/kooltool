local Class = require "hump.class"
local Collider = require "collider"
local EditMode = require "editmode"
local Sprite = require "sprite"
local Entity = require "entity"

local generators = require "generators"
local common = require "common"
local brush = require "brush"

local PlaceMode = Class { __includes = EditMode, name = "place entities" }

local EntityLayer = Class {}

function EntityLayer:deserialise(data, saves)
    local sprite_path = saves .. "/sprites"

    -- HACK: to support old saves for now TODO remove
    if data.sprites_id then
        self.sprites_index.id = data.sprites_id

        for id, sprite_data in pairs(data.sprites) do
            local file = sprite_path .. "/" .. id .. ".png"
            local sprite = Sprite()
            sprite.canvas = common.loadCanvas(file)

            sprite.pivot = sprite_data.pivot

            self:addSprite(sprite, id)
        end

        for i, entity_data in ipairs(data.entities) do
            local entity = Entity(self)
            entity:deserialise(entity_data)
            self:addEntity(entity)
        end
    end
end

function EntityLayer:serialise(saves)
    local sprite_path = saves .. "/sprites"
    love.filesystem.createDirectory(sprite_path)

    local sprites = {}

    for sprite, id in pairs(self.sprites) do
        local file = sprite_path .. "/" .. id .. ".png"
        local data = sprite.canvas:getImageData()
        data:encode(file)

        sprites[id] = {
            pivot = sprite.pivot,
        }
    end

    local entities = {}

    for entity in pairs(self.entities) do
        table.insert(entities, entity:serialise(saves))
    end

    return {
        sprites_id = self.sprites_index.id,
        sprites = sprites,
        entities = entities,
    }
end

function EntityLayer:init()
    self.active = true

    self.modes = {
        place = PlaceMode(self),
    }

    self.sprites = {}
    self.sprites_index = {id = 0}
    self.entities = {}
    self.collider = Collider(64)
end

function EntityLayer:draw()
    for entity in pairs(self.entities) do
        entity:draw()
    end
end

function EntityLayer:addSprite(sprite, id)
    if not id then
        id = self.sprites_index.id + 1
        self.sprites_index.id = id
    end

    self.sprites[sprite] = id
    self.sprites_index[id] = sprite
end

function EntityLayer:addEntity(entity)
    self.entities[entity] = true
    self.collider:addShape(entity.shape)
end

function EntityLayer:removeEntity(entity)
    self.entities[entity] = nil
    self.collider:remove(entity.shape)
end

function EntityLayer:swapShapes(old, new)
    self.collider:remove(old)
    self.collider:addShape(new)
end

function EntityLayer:applyBrush(bx, by, brush, entity, lock, cloning)
    entity:applyBrush(bx, by, brush, lock, cloning)
end

function EntityLayer:sample(x, y)
    local shape = self.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    local colour = entity and entity:sample(x, y) or {0, 0, 0, 0}
    colour = colour[4] ~= 0 and colour or PROJECT.tilelayer:sample(x, y)

    return colour
end

function PlaceMode:draw()
    if love.keyboard.isDown("lshift") then
        for entity in pairs(self.layer.entities) do
            entity:border()
        end
    elseif self.state.selected then
        self.state.selected:border()
    end
end

function PlaceMode:hover(x, y, dt)
    if self.state.drag then
        local entity, dx, dy = unpack(self.state.drag)

        entity:moveTo(x + dx, y + dy)
    end
end

function PlaceMode:mousepressed(x, y, button)
    local shape = self.layer.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    if button == "l" then
        if entity then
            local dx, dy = entity.x - x, entity.y - y
        
            self.state.drag = {entity, dx, dy}
            self.state.selected = entity
        else
            self.state.selected = nil
        end
    elseif button == "m" then
        if entity then
            self.layer:removeEntity(entity)
            if self.state.selected == entity then
                self.state.selected = nil
            end
        else
            local entity = Entity(self.layer)
            entity:blank(x, y)
            self.layer:addEntity(entity)
            self.state.selected = entity
        end
    end
end

function PlaceMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.drag = nil

        if self.state.selected then
            local entity = self.state.selected
            entity:moveTo(math.floor(entity.x / 32) * 32 + 16,
                          math.floor(entity.y / 32) * 32 + 16)
        end
    end
end

return EntityLayer

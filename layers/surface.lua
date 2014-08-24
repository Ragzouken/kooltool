local Class = require "hump.class"
local Collider = require "collider"
local Layer = require "layers.layer"

local Tileset = require "components.tileset"
local Sprite = require "components.sprite"
local Entity = require "components.entity"

local SparseGrid = require "utilities.sparsegrid"
local common = require "utilities.common"

local SurfaceLayer = Class {
    __includes = Layer,
    tilesize = {32, 32},
    clone_sound = love.audio.newSource("sounds/clone.wav"),
}

function SurfaceLayer:deserialise_entity(data, saves)
    local sprite_path = saves .. "/sprites"

    self.sprites_index.id = data.sprites_id

    for id, sprite_data in pairs(data.sprites) do
        local file = sprite_path .. "/" .. id .. ".png"
        local sprite = Sprite()
        sprite.canvas = common.loadCanvas(file)

        sprite.pivot = sprite_data.pivot
        sprite:refresh()

        self:addSprite(sprite, id)
    end

    for i, entity_data in ipairs(data.entities) do
        local entity = Entity(self)
        entity:deserialise(entity_data)
        self:addEntity(entity)
    end
end

function SurfaceLayer:serialise_entity(saves)
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

function SurfaceLayer:serialise(saves)
    local tiles = {[0]={[0]=0}}

    for tile, x, y in self.tilemap:items() do
        tiles[y] = tiles[y] or {[0]=0}
        tiles[y][x] = tile[1]
    end

    local walls = {[0]={[0]=""}}

    for wall, x, y in self.wallmap:items() do
        walls[y] = walls[y] or {[0]=""}
        walls[y][x] = wall
    end

    return {
        tileset = self.tileset:serialise(saves),
        tiles = tiles,
        walls = walls,
        wall_index = {[0]=false, unpack(self.wall_index)},
    }
end

function SurfaceLayer:exportRegions(folder_path)
    local regions = self.tilemap:regions()

    love.filesystem.createDirectory(folder_path .. "/regions")

    for i, region in ipairs(regions) do
        local text = ""
        local lasty

        for item, x, y in region:rectangle() do
            if lasty and lasty ~= y then
                text = text .. "\n"
            elseif lasty then
                text = text .. ","
            end

            lasty = y

            text = text .. (item and item[1] or 0)
        end

        text = text .. "\n"

        local file = love.filesystem.newFile(folder_path
            .. "/regions/" .. i .. ".txt", "w")
        file:write(text)
        file:close()
    end
end

function SurfaceLayer:deserialise(data, saves)
    self.tileset:deserialise(data.tileset, saves)

    for y, row in pairs(data.tiles) do
        for x, index in pairs(row) do
            if index > 0 then self:setTile(index, tonumber(x), tonumber(y)) end
        end
    end

    for y, row in pairs(data.walls or {}) do
        for x, wall in pairs(row) do
            if wall ~= "" then
                self.wallmap:set(wall, tonumber(x), tonumber(y))
            end
        end
    end

    self.wall_index = {[0] = false}

    for index, solid in pairs(data.wall_index or {}) do
        self.wall_index[tonumber(index)] = solid
    end
end

function SurfaceLayer:init(project)
    Layer.init(self, project)

    self.collider = Collider(64)

    self.tileset = Tileset()
    self.tilemap = SparseGrid(unpack(self.tilesize))
    self.tilebatch = love.graphics.newSpriteBatch(common.BROKEN, 7500)

    self.wall_index = {}
    self.wallmap = SparseGrid(unpack(self.tilesize))
    
    self.sprites = {}
    self.sprites_index = {id = 0}
    self.entities = {}
end

function SurfaceLayer:draw()
    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(255, 255, 255, 255)
    
    if not self.tileset.canvas.fake then
        self.tilebatch:setTexture(self.tileset.canvas)
    else
        self.tilebatch:setTexture(self.tileset.canvas.image)
    end

    love.graphics.draw(self.tilebatch, 0, 0)

    for entity in pairs(self.entities) do
        entity:draw()
    end
end

function SurfaceLayer:objectAt(x, y)
    local shape = self.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    return entity
end

function SurfaceLayer:getTile(gx, gy)
    local tile = self.tilemap:get(gx, gy)

    return tile and tile[1]
end

function SurfaceLayer:setTile(index, gx, gy)
    local current = self.tilemap:get(gx, gy)
    local id = current and current[2]
    local tw, th = unpack(self.tilesize)

    if index and index ~= 0 then
        local quad = self.tileset.quads[index]

        if id then
            self.tilebatch:set(id, quad, gx * tw, gy * th)
        else
            id = self.tilebatch:add(quad, gx * tw, gy * th)
        end

        self.tilemap:set({index, id}, gx, gy)

        return (not current) or (current[1] ~= index)
    else
        if id then
            self.tilebatch:set(id, gx * tw, gy * th, 0, 0, 0)
        end

        self.tilemap:set(nil, gx, gy)

        return current or false
    end
end

function SurfaceLayer:getWall(gx, gy)
    local tile = self:getTile(gx, gy) or 0
    local wall = self.wallmap:get(gx, gy)

    print(wall, self.wall_index[tile])

    return (wall == nil and self.wall_index[tile]) or wall 
end

function SurfaceLayer:setWall(solid, gx, gy, clone)
    local index = self:getTile(gx, gy)
    local default = self.wall_index[index]
    local instance = self.wallmap:get(gx, gy)

    if not clone and index and instance == nil then
        self.wall_index[index] = solid or nil
        return (default and not solid) or (solid and not default)
    elseif default then
        if (solid and not default) or (default and not solid) then
            self.wallmap:set(solid, gx, gy)
            return instance ~= solid
        elseif instance ~= nil and instance ~= solid then
            self.wallmap:set(nil, gx, gy)
            return true
        end
    else
        self.wallmap:set(solid or nil, gx, gy)
        return (not instance) ~= (not solid)
    end

    return false
end

function SurfaceLayer:addSprite(sprite, id)
    if not id then
        id = self.sprites_index.id + 1
        self.sprites_index.id = id
    end

    self.sprites[sprite] = id
    self.sprites_index[id] = sprite
end

function SurfaceLayer:addEntity(entity)
    self.entities[entity] = true
    self.collider:addShape(entity.shape)
end

function SurfaceLayer:removeEntity(entity)
    self.entities[entity] = nil
    self.collider:remove(entity.shape)
end

function SurfaceLayer:swapShapes(old, new)
    self.collider:remove(old)
    self.collider:addShape(new)
end

function SurfaceLayer:refresh()
    for tile, x, y in self.tilemap:items() do
        self:setTile(tile[1], x, y)
    end
end

function SurfaceLayer:applyBrush(bx, by, brush, lock, cloning)
    local gx, gy, tx, ty = self.tilemap:gridCoords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile TODO: (if unlocked)
    local bw, bh = brush:getDimensions()
    local size = 32

    local gw, gh = math.ceil((bw + tx) / size), math.ceil((bh + ty) / size)
    local quad = love.graphics.newQuad(0, 0, size, size, bw, bh)

    local cloned

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local index = self:getTile(gx + x, gy + y)
            quad:setViewport(-tx + x * size, -ty + y * size, size, size)

            local locked = lock and (lock[1] ~= x+gx or lock[2] ~= y+gy)
            local key = tostring(gx + x) .. "," .. tostring(gy + y)

            if cloning and not cloning[key] and not locked then
                index = self.tileset:clone(index)
                self:setTile(index, gx + x, gy + y)
                cloning[key] = true
                cloned = true
            end

            if index and not locked then
                self.tileset:applyBrush(index, brush, quad)
                self.tileset:refresh()
            end
        end
    end

    if cloned then
        self:refresh()
        self.clone_sound:stop()
        self.clone_sound:play()
    end
end

function SurfaceLayer:sample(x, y)
    local shape = self.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    if entity then
        local colour = entity and entity:sample(x, y) or {0, 0, 0, 0}
        if colour[4] ~= 0 then return colour end
    end

    local gx, gy, ox, oy = self.tilemap:gridCoords(x, y)
    local index = self:getTile(gx, gy)

    return index and self.tileset:sample(index, ox, oy) or {0, 0, 0, 255}
end

return SurfaceLayer

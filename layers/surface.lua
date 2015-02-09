local Class = require "hump.class"
local Layer = require "layers.layer"

local Tileset = require "components.tileset"
local Sprite = require "components.sprite"
local Entity = require "components.entity"

local SparseGrid = require "utilities.sparsegrid"
local common = require "utilities.common"

local json = require "utilities.dkjson"

local SurfaceLayer = Class {
    __includes = Layer,
    type = "SurfaceLayer",
    name = "kooltool surface layer",

    actions = { "draw", "tile", "entity" },

    clone_sound = love.audio.newSource("sounds/clone.wav"),
}

function SurfaceLayer:serialise(resources)
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

    local entities = {}

    for entity in pairs(self.entities) do
        table.insert(entities, resources:reference(entity))
    end

    return {
        project = resources:reference(self.project),
        tileset = resources:reference(self.tileset),
        tiles = tiles,
        walls = walls,
        wall_index = {[0]=false, unpack(self.wall_index)},
        entities = entities,
    }
end

function SurfaceLayer:deserialise(resources, data)
    self.project = resources:resource(data.project) or MODE.project -- TODO: remove this
    self.tileset = resources:resource(data.tileset)
    
    for y, row in pairs(data.tiles) do
        for x, index in pairs(row) do
            if index > 0 then 
                local gx, gy = tonumber(x), tonumber(y)

                self.tilemap:set({index}, gx, gy)
            end
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

    for i, reference in ipairs(data.entities) do
        local entity = resources:resource(reference)

        self:addEntity(entity)
    end
end

function SurfaceLayer:init(project)
    Layer.init(self, project)

    self.tileset = nil
    self.tilemap = SparseGrid()
    self.tilebatch = love.graphics.newSpriteBatch(common.BROKEN, 1024 * 1024)

    self.wall_index = {}
    self.wallmap = SparseGrid()
    
    self.sprites = {}
    self.sprites_index = {id = 0}
    self.entities = {}

    self._refresh = function() self:refresh() end
end

function SurfaceLayer:finalise()
    for entity in pairs(self.entities) do
        self.project:add_sprite(entity.sprite)
    end

    self:SetTileset(self.tileset)
    self:refresh()
end

function SurfaceLayer:draw(params)
    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(255, 255, 255, 255)
    
    if not self.tileset.canvas.fake then
        self.tilebatch:setTexture(self.tileset.canvas)
    else
        self.tilebatch:setTexture(self.tileset.canvas.image)
    end

    love.graphics.draw(self.tilebatch, 0, 0)
end



function SurfaceLayer:SetTileset(tileset)
    self.tileset = tileset
    
    self.tilemap:SetCellSize(unpack(self.tileset.dimensions))
    self.wallmap:SetCellSize(unpack(self.tileset.dimensions))

    self.tileset.changed:add(self._refresh)
end

function SurfaceLayer:getTile(gx, gy)
    local tile = self.tilemap:get(gx, gy)

    return tile and tile[1]
end

function SurfaceLayer:setTile(index, gx, gy)
    local current = self.tilemap:get(gx, gy)
    local id = current and current[2]
    local tw, th = unpack(self.tileset.dimensions)

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

function SurfaceLayer:toggleWall(gx, gy, instanced)
    local index = self:getTile(gx, gy)
    local default = self.wall_index[index]
    local instance = self.wallmap:get(gx, gy)

    if not index then return false end

    if instanced then
        local value

        if instance ~= nil then
            value = nil
        elseif default ~= nil then
            value = not default
        end

        self.wallmap:set(value, gx, gy)
    else
        self.wall_index[index] = not default
    end

    return true
end

function SurfaceLayer:addEntity(entity)
    self.entities[entity] = true
    entity.layer = self

    self:add(entity)
end

function SurfaceLayer:removeEntity(entity)
    self.entities[entity] = nil

    self:remove(entity)
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
    local tw, th = unpack(self.tileset.dimensions)

    local gw, gh = math.ceil((bw + tx) / tw), math.ceil((bh + ty) / th)
    local quad = love.graphics.newQuad(0, 0, tw, th, bw, bh)

    local cloned

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local index = self:getTile(gx + x, gy + y)
            quad:setViewport(-tx + x * tw, -ty + y * th, tw, th)

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
            end
        end
    end

    if cloned then
        self.clone_sound:stop()
        self.clone_sound:play()
    end
end

function SurfaceLayer:sample(x, y)
    local gx, gy, ox, oy = self.tilemap:gridCoords(x, y)
    local index = self:getTile(gx, gy)

    return index and self.tileset:sample(index, ox, oy) or {0, 0, 0, 255}
end

return SurfaceLayer

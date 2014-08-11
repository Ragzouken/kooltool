local Class = require "hump.class"
local Layer = require "layers.layer"
local SparseGrid = require "sparsegrid"
local Tileset = require "tileset"

local common = require "common"

local SurfaceLayer = Class {
    __includes = Layer,
    tilesize = {32, 32},
}

function SurfaceLayer:serialise(saves)
    local tiles = {[0]={[0]=0}}

    for tile, x, y in self.tilemap:items() do
        tiles[y] = tiles[y] or {[0]=0}
        tiles[y][x] = tile[1]
    end

    local walls = {[0]={[0]=false}}

    for wall, x, y in self.wallmap:items() do
        walls[y] = walls[y] or {[0]=false}
        walls[y][x] = wall
    end

    return {
        tileset = self.tileset:serialise(saves),
        tiles = tiles,
        walls = walls,
        wall_index = self.wall_index,
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

        local file = love.filesystem.newFile(folder_path .. "/regions/" .. i .. ".txt", "w")
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
            self.wallmap:set(wall or nil, tonumber(x), tonumber(y))
        end
    end

    self.wall_index = {[0] = false}

    for index, solid in pairs(data.wall_index or {}) do
        self.wall_index[tonumber(index)] = solid
    end
end

function SurfaceLayer:init(project)
    Layer.init(self, project)

    self.tileset = Tileset()
    self.tilemap = SparseGrid(unpack(self.tilesize))
    self.tilebatch = love.graphics.newSpriteBatch(common.BROKEN, 7500)

    self.wall_index = {}
    self.wallmap = SparseGrid(unpack(self.tilesize))
    
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
    else
        if id then
            self.tilebatch:set(id, gx * tw, gy * th, 0, 0, 0)
        end

        self.tilemap:set(nil, gx, gy)
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
            self.wallmaps:set(nil, gx, gy)
            return true
        end
    else
        self.wallmap:set(solid or nil, gx, gy)
        return true
    end

    return false
end

function SurfaceLayer:refresh()
    for tile, x, y in self.tilemap:items() do
        self:setTile(tile[1], x, y)
    end
end

return SurfaceLayer

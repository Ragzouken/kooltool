local Class = require "hump.class"

local SparseGrid = require "utilities.SparseGrid"

local Event = require "utilities.event"

local TileMap = Class {
    type = "TileMap",
}

function TileMap:serialise(resources)
    local data = {}

    data.tileset = resources:reference(self.tileset)
    
    data.tiledata = self.tiledata:serialise(function(item, x, y)
        return item.tile
    end)

    return data
end

function TileMap:deserialise(resources, data)
end

function TileMap:finalise(resources, data)
    self:set_tileset(resources:resource(data.tileset))

    self.tiledata:deserialise(function(item, x, y)
        self:set(item, x, y)

        return nil
    end, data.tiledata)
end

function TileMap:init()
    self.tileset = nil
    self.tiledata = SparseGrid(32)
    self.tilebatch = love.graphics.newSpriteBatch(love.graphics.newCanvas(32, 32), 1024 * 1024)

    self.changed = Event()

    self.free_sprites = {}
end

function TileMap:draw()
    love.graphics.draw(self.tilebatch)
end

function TileMap:set_tileset(tileset)
    self.tileset = tileset

    if not self.tileset.canvas.fake then
        self.tilebatch:setTexture(self.tileset.canvas)
    else
        self.tilebatch:setTexture(self.tileset.canvas.image)
    end
end

function TileMap:set(tile, x, y)
    local previous = self.tiledata:get(x, y)
    local current = { tile = tile }

    local tw, th = unpack(self.tiledata.cell_dimensions)

    local changed = false

    if tile and tile ~= 0 then
        local quad = self.tileset.quads[tile]

        if previous then
            current.sprite = previous.sprite
        elseif #self.free_sprites > 0 then
            current.sprite = table.remove(self.free_sprites)
        end

        if current.sprite then
            self.tilebatch:set(current.sprite, quad, x * tw, y * th)
        else
            current.sprite = self.tilebatch:add(quad, x * tw, y * th)
        end

        self.tiledata:set(current, x, y)

        --self.changed:fire(current.tile, previous and previous.tile)
        changed = not previous or current.tile ~= previous.tile 
    else
        if previous then
            self.tilebatch:set(previous.sprite, x * tw, y * th, 0, 0, 0)
            table.insert(self.free_sprites, previous.sprite)

            --self.changed:fire(nil, previous.tile)
            changed = true
        end

        self.tiledata:set(nil, x, y)

        return changed
    end

    return changed
end

function TileMap:get(x, y)
    local data = self.tiledata:get(x, y)

    return data and data.tile
end

function TileMap:brush(brush, bx, by, options)
    local gx, gy, tx, ty = self.tiledata:grid_coords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile TODO: (if unlocked)
    local bw, bh = brush:getDimensions()
    local tw, th = unpack(self.tiledata.cell_dimensions)

    local gw, gh = math.ceil((bw + tx) / tw), math.ceil((bh + ty) / th)
    local quad = love.graphics.newQuad(0, 0, tw, th, bw, bh)

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local index = self:get(gx + x, gy + y)
            quad:setViewport(-tx + x * tw, -ty + y * th, tw, th)

            local locked = options.lock and (options.lock[1] ~= x+gx or options.lock[2] ~= y+gy)
            local key = tostring(gx + x) .. "," .. tostring(gy + y)

            if options.cloning and not options.cloning[key] and not locked then
                index = self.tileset:clone(index)
                self:set(index, gx + x, gy + y)
                options.cloning[key] = true
            end

            if index and not locked then
                self.tileset:applyBrush(index, brush, quad)
            end
        end
    end
end

function TileMap:sample(x, y)
    local gx, gy, px, py = self.tiledata:grid_coords(x, y)
    local index = self:get(gx, gy)

    return index and self.tileset:sample(index, px, py)
end

return TileMap

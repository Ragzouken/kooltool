local Class = require "hump.class"
local SparseGrid = require "sparsegrid"
local EditMode = require "editmode"
local Tileset = require "tileset"

local generators = require "generators"
local bresenham = require "bresenham"
local Brush = require "brush"
local colour = require "colour"

local TileMode = Class { __includes = EditMode, name = "tile placement" }
local PixelMode = Class { __includes = EditMode, name = "edit pixels" }

local TileLayer = Class {}

function TileLayer:init(project)
    self.project = project

    self.active = true

    self.modes = {
        tile = TileMode(self.project.layers.surface),
        pixel = PixelMode(self.project.layers.surface),
    }
end

function TileLayer:applyBrush(bx, by, brush, lock, cloning)
    local gx, gy, tx, ty = self.project.layers.surface.tilemap:gridCoords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile TODO: (if unlocked)
    local bw, bh = brush:getDimensions()
    local size = 32

    local gw, gh = math.ceil((bw + tx) / size), math.ceil((bh + ty) / size)
    local quad = love.graphics.newQuad(0, 0, size, size, bw, bh)

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local index = self.project.layers.surface:getTile(gx + x, gy + y)
            quad:setViewport(-tx + x * size, -ty + y * size, size, size)

            local locked = lock and (lock[1] ~= x+gx or lock[2] ~= y+gy)
            local key = tostring(gx + x) .. "," .. tostring(gy + y)

            if cloning and not cloning[key] and not locked then
                index = self.project.layers.surface.tileset:clone(index)
                self.project.layers.surface:setTile(index, gx + x, gy + y)
                cloning[key] = true
            end

            if index and not locked then
                self.project.layers.surface.tileset:applyBrush(index, brush, quad)
                self.project.layers.surface.tileset:refresh()
            end
        end
    end

    if cloning then self.project.layers.surface:refresh() end
end

function TileLayer:sample(x, y)
    local shape = self.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    if entity then
        local colour = entity and entity:sample(x, y) or {0, 0, 0, 0}
        if colour[4] ~= 0 then return colour end
    end

    local gx, gy, ox, oy = self.project.layers.surface.tilemap:gridCoords(x, y)
    local index = self.project.layers.surface:getTile(gx, gy)

    return index and self.project.layers.surface.tileset:sample(index, ox, oy) or {0, 0, 0, 255}
end

function PixelMode:hover(x, y, dt)
    if self.state.draw then
        local dx, dy, subject = unpack(self.state.draw)

        local brush, ox, oy = Brush.line(dx, dy, x, y, BRUSHSIZE, PALETTE.colours[3])
        subject:applyBrush(ox, oy, brush, self.state.lock or self.state.locked_entity, self.state.cloning)

        self.state.draw = {x, y, subject}
    end
end

function PixelMode:draw(x, y)
    local gx, gy, ox, oy = self.layer.tilemap:gridCoords(x, y)
    local tsize = 32

    local size = BRUSHSIZE
    local le = math.floor(size / 2)

    love.graphics.setColor(PALETTE.colours[3])
    love.graphics.rectangle("fill", math.floor(x)-le, math.floor(y)-le, size, size)

    local shape = PROJECT.tilelayer.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    if self.state.locked_entity then
        self.state.locked_entity:border()
    end

    if self.state.draw and self.state.draw[3].border then
        self.state.draw[3]:border()
    elseif entity and not self.state.draw then
        entity:border()
    else
        if self.state.lock then
            love.graphics.setColor(colour.random(128, 255))

            local lx, ly = unpack(self.state.lock)
            love.graphics.rectangle("line", lx*tsize-0.5, ly*tsize-0.5, tsize+1, tsize+1)
        end

        if love.keyboard.isDown("lshift") then
            for entity in pairs(PROJECT.entitylayer.entities) do
                entity:border()
            end
        end
    end
end

function PixelMode:mousepressed(x, y, button)
    local shape = PROJECT.tilelayer.collider:shapesAt(x, y)[1]
    local entity = shape and shape.entity

    if button == "l" then
        if love.keyboard.isDown("lalt") then
            PALETTE.colours[3] = PROJECT.tilelayer:sample(x, y)
        else
            if not entity then self.layer.tileset:snapshot(7) end
            self.state.draw = {x, y, entity or PROJECT.tilelayer} 
        end

        return true
    end

    return false
end

function PixelMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
    end
end

function PixelMode:keypressed(key, isrepeat)
    if not isrepeat then
        local x, y = CAMERA:mousepos()
        local shape = PROJECT.tilelayer.collider:shapesAt(x, y)[1]
        local entity = shape and shape.entity

        if entity and key == "lshift" then
            self.state.locked_entity = entity
            return
        end

        if not entity or self.state.draw then
            if key == "lshift" then
                local mx, my = CAMERA:mousepos()
                self.state.lock = {self.layer.tilemap:gridCoords(mx, my)}
            elseif key == "lctrl" then
                self.state.cloning = {}
            end
        end

        if key == "1" then BRUSHSIZE = 1 end
        if key == "2" then BRUSHSIZE = 2 end
        if key == "3" then BRUSHSIZE = 3 end

        if key == " " then
            PALETTE = generators.Palette.generate(5)
        end
    end
end

function PixelMode:keyreleased(key)
    if key == "lshift" then
        self.state.lock = nil 
        self.state.locked_entity = nil
    elseif key == "lctrl" then
        self.state.cloning = nil
    end
end

function TileMode:hover(x, y, dt)
    local gx, gy = self.layer.tilemap:gridCoords(x, y)
    local tile = self.layer:getTile(gx, gy)
    local clone = love.keyboard.isDown("lctrl")
    local change

    if self.state.draw then
        local ox, oy = unpack(self.state.draw)

        if love.keyboard.isDown("lshift") then
            for lx, ly in bresenham.line(ox, oy, gx, gy) do
                change = change or self.layer:setWall(true, lx, ly, clone)
            end
        else
            for lx, ly in bresenham.line(ox, oy, gx, gy) do
                self.layer:setTile(TILE, lx, ly)
            end

            change = tile ~= TILE
        end

        self.state.draw = {gx, gy}
    elseif self.state.erase then
        local ox, oy = unpack(self.state.erase)

        if love.keyboard.isDown("lshift") then
            for lx, ly in bresenham.line(ox, oy, gx, gy) do
                change = change or self.layer:setWall(false, lx, ly, clone)
            end
        else
            for lx, ly in bresenham.line(ox, oy, gx, gy) do
                self.layer:setTile(nil, lx, ly)
            end

            change = change or tile
        end

        self.state.erase = {gx, gy}
    end

    if change then
        TILESOUND:stop()
        TILESOUND:play()
    end
end

function TileMode:draw(x, y)
    love.graphics.setBlendMode("alpha")
    local gx, gy, ox, oy = self.layer.tilemap:gridCoords(x, y)
    local size = 32

    local wall_alpha = math.random(96, 160)

    if love.keyboard.isDown("lshift") then
        for tile, x, y in self.layer.tilemap:items() do
            local wall = PROJECT.layers.surface.wallmap:get(x, y)

            if wall == nil and self.layer.wall_index[tile[1]] then
                love.graphics.setColor(255, 0, 0, wall_alpha)
                love.graphics.rectangle("fill", x * size, y * size, size, size)
            end
        end

        for wall, x, y in self.layer.wallmap:items() do
            if wall then
                love.graphics.setColor(255, 0, 0, wall_alpha)
            else
                love.graphics.setColor(0, 255, 0, wall_alpha)
            end

            love.graphics.rectangle("fill", x * size, y * size, size, size)
        end

        love.graphics.setColor(255, 0, 0, 128)
        love.graphics.rectangle("fill", gx*size, gy*size, size, size)
    else
        local quad = self.layer.tileset.quads[TILE]

        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.draw(self.layer.tileset.canvas, quad, gx * size, gy * size)
    end

    love.graphics.setColor(colour.random(128, 255))
    love.graphics.rectangle("line", gx*size-0.5, gy*size-0.5, size+1, size+1)
end

function TileMode:mousepressed(x, y, button)
    local gx, gy = self.layer.tilemap:gridCoords(x, y)

    if button == "l" then
        if love.keyboard.isDown("lalt") then
            TILE = self.layer:getTile(gx, gy) or TILE
        else
            self.state.draw = {gx, gy}
        end

        return true
    elseif button == "m" then
        self.state.erase = {gx, gy}

        return true
    end

    return false
end

function TileMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
    elseif button == "m" then
        self.state.erase = nil
    end
end

return TileLayer

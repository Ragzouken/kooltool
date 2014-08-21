local Class = require "hump.class"
local EditMode = require "editmode"

local Entity = require "entity"
local Notebox = require "notebox"
local Brush = require "brush"

local generators = require "generators"
local bresenham = require "utilities.bresenham"
local colour = require "colour"

local ObjectMode = Class {
    __includes = EditMode,

    typing_sound = love.audio.newSource("sounds/typing.wav"),
}
local TileMode = Class { __includes = EditMode, name = "place tiles and walls" }
local AnnotateMode = Class { __includes = EditMode, name = "annotate project" }

function TileMode:update(dt)
    self.active = false
end

function TileMode:hover(x, y, dt)
    self.active = true

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

    if love.keyboard.isDown("lshift") then
        for tile, x, y in self.layer.tilemap:items() do
            local wall = PROJECT.layers.surface.wallmap:get(x, y)

            if wall == nil and self.layer.wall_index[tile[1]] then
                love.graphics.setColor(colour.walls(0, 0))
                love.graphics.rectangle("fill", x * size, y * size, size, size)
            end
        end

        for wall, x, y in self.layer.wallmap:items() do
            if wall then
                love.graphics.setColor(colour.walls(0, 0))
            else
                love.graphics.setColor(colour.walls(0, 85))
            end

            love.graphics.rectangle("fill", x * size, y * size, size, size)
        end

        love.graphics.setColor(255, 0, 0, 128)
        love.graphics.rectangle("fill", gx*size, gy*size, size, size)
    elseif self.active then
        local quad = self.layer.tileset.quads[TILE]

        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.draw(self.layer.tileset.canvas, quad, gx * size, gy * size)
    end

    if self.active then
        love.graphics.setColor(colour.cursor(0))
        love.graphics.rectangle("line", gx*size-0.5, gy*size-0.5, size+1, size+1)
    end
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

function AnnotateMode:hover(x, y, dt)
    if self.state.draw then
        local dx, dy = unpack(self.state.draw)
        local brush, ox, oy

        if not love.keyboard.isDown("lctrl") then
            brush, ox, oy = Brush.line(dx, dy, x, y, BRUSHSIZE, {255, 255, 255, 255})
        else
            brush, ox, oy = Brush.line(dx, dy, x, y, BRUSHSIZE * 3)
        end

        self.layer:applyBrush(ox, oy, brush)

        self.state.draw = {x, y}
    end
end

function AnnotateMode:mousepressed(x, y, button)
    self.state.selected = PROJECT:objectAt(x, y)

    if button == "l" then
        self.state.draw = {x, y}

        return true
    end

    return false
end

function AnnotateMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
    end
end

function AnnotateMode:keypressed(key)
    if self.state.selected and self.state.selected:keypressed(key) then
        return true
    end

    if key == "1" then BRUSHSIZE = 1 return true end
    if key == "2" then BRUSHSIZE = 2 return true end
    if key == "3" then BRUSHSIZE = 3 return true end

    return false
end

function AnnotateMode:textinput(character)
    if self.state.selected and self.state.selected:textinput(character) then
        return true
    end
end

return {{}, TileMode, AnnotateMode}

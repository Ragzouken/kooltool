local Class = require "hump.class"
local EditMode = require "editmode"

local Entity = require "entity"
local Notebox = require "notebox"
local Brush = require "brush"

local generators = require "generators"
local bresenham = require "bresenham"
local colour = require "colour"

local DragDeleteMode = Class { __includes = EditMode, }
local TileMode = Class { __includes = EditMode, name = "tile placement" }
local PixelMode = Class { __includes = EditMode, name = "edit pixels" }
local AnnotateMode = Class { __includes = EditMode, name = "annotate project" }

--

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

    if self.state.locked_entity then
        self.state.locked_entity:border()
    end

    local entity = self.layer:objectAt(x, y)

    if self.state.draw and self.state.draw[3].border then
        self.state.draw[3]:border()
    elseif entity and not self.state.draw then
        entity:border()
    else
        if self.state.lock then
            love.graphics.setColor(colour.cursor(0))

            local lx, ly = unpack(self.state.lock)
            love.graphics.rectangle("line", lx*tsize-0.5, ly*tsize-0.5, tsize+1, tsize+1)
        end

        if love.keyboard.isDown("lshift") then
            for entity in pairs(self.layer.entities) do
                entity:border()
            end
        end
    end
end

function PixelMode:mousepressed(x, y, button)
    local entity = self.layer:objectAt(x, y)

    if button == "l" then
        if love.keyboard.isDown("lalt") then
            PALETTE.colours[3] = self.layer:sample(x, y)
        else
            if not entity then self.layer.tileset:snapshot(7) end
            self.state.draw = {x, y, entity or self.layer} 
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
        local entity = self.layer:objectAt(CAMERA:mousepos())

        if entity and key == "lshift" then
            self.state.locked_entity = entity
            return
        end

        if not entity or self.state.draw then
            if key == "lshift" then
                self.state.lock = {self.layer.tilemap:gridCoords(CAMERA:mousepos())}
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

    if self.state.drag then
        local object, dx, dy = unpack(self.state.drag)

        object:moveTo(x + dx, y + dy)
    elseif self.state.draw then
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

    if not self.state.draw and not self.state.erase and not self.state.drag then
        local entity = self.layer:objectAt(x, y)
        local notebox = self.layer.project.layers.annotation:objectAt(x, y)

        if entity then entity:border() return end
        if notebox then return end
    elseif self.state.drag then
        if self.state.drag[1].border then
            self.state.drag[1]:border()
        end

        return
    end

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
    else
        local quad = self.layer.tileset.quads[TILE]

        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.draw(self.layer.tileset.canvas, quad, gx * size, gy * size)
    end

    love.graphics.setColor(colour.cursor(0))
    love.graphics.rectangle("line", gx*size-0.5, gy*size-0.5, size+1, size+1)
end

function TileMode:mousepressed(x, y, button)
    local gx, gy = self.layer.tilemap:gridCoords(x, y)

    local draggable = self.layer.project:objectAt(x, y)

    if button == "l" then
        if draggable then
            local dx, dy = draggable.x - x, draggable.y - y
        
            self.state.drag = {draggable, dx, dy}
        else
            if love.keyboard.isDown("lalt") then
                TILE = self.layer:getTile(gx, gy) or TILE
            else
                self.state.draw = {gx, gy}
            end
        end

        return true
    elseif button == "m" then
        if draggable and draggable.sprite then
            self.layer:removeEntity(draggable)
        elseif draggable then
            self.layer.project.layers.annotation:removeNotebox(draggable)
        else
            self.state.erase = {gx, gy}
        end

        return true
    end

    return false
end

function TileMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.draw = nil
        self.state.drag = nil
    elseif button == "m" then
        self.state.erase = nil
    end
end

function AnnotateMode:update(dt)
    if self.state.selected and ZOOM < 2 then self.state.selected = nil end

    if self.state.selected then
        self.name = "annotate project (typing)"
    else
        self.name = "annotate project"
    end
end

function AnnotateMode:draw()
    if self.state.drag and self.state.drag[1].border then
        self.state.drag[1]:border()
    end

    if not self.state.draw or self.state.erase or self.state.drag then
        local x, y = CAMERA:mousepos()
        local entity = PROJECT.layers.surface:objectAt(x, y)

        if entity then entity:border() end
    end
end

function AnnotateMode:hover(x, y, dt)
    if self.state.drag then
        local object, dx, dy = unpack(self.state.drag)

        object:moveTo(x + dx, y + dy)
    elseif self.state.draw then
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

    for notebox in pairs(self.layer.noteboxes) do
        if notebox.text == "" and notebox ~= self.state.selected then
            self.layer:removeNotebox(notebox)
        end
    end
end

function AnnotateMode:mousepressed(x, y, button)
    local notebox = self.layer:objectAt(x, y)
    local draggable = PROJECT.layers.surface:objectAt(x, y)

    if button == "l" then
        if notebox then
            local dx, dy = notebox.x - x, notebox.y - y
        
            self.state.drag = {notebox, dx, dy}
            self.state.selected = notebox
        elseif draggable then
            local dx, dy = draggable.x - x, draggable.y - y
        
            self.state.drag = {draggable, dx, dy}
            self.state.selected = nil
        else
            self.state.draw = {x, y}
            self.state.selected = nil
        end

        return true
    elseif button == "m" then
        if notebox then
            self.layer:removeNotebox(notebox)
            self.state.selected = nil

            return true
        end
    end

    return false
end

function AnnotateMode:mousereleased(x, y, button)
    if button == "l" then
        self.state.drag = nil
        self.state.draw = nil
    end
end

function AnnotateMode:keypressed(key)
    local selected = self.state.selected

    if selected then
        if key == "escape" then
            self.state.selected = nil
        else
            return selected:keypressed(key)
        end

        return true
    end

    if key == "1" then BRUSHSIZE = 1 end
    if key == "2" then BRUSHSIZE = 2 end
    if key == "3" then BRUSHSIZE = 3 end

    return false
end

function AnnotateMode:textinput(text)
    local selected = self.state.selected

    if selected then
        selected:textinput(text)
        return true
    end

    return false
end

return {PixelMode, TileMode, AnnotateMode}

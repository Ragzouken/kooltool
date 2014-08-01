local Class = require "hump.class"
local Collider = require "collider"
local SparseGrid = require "sparsegrid"
local Notebox = require "notebox"

local colour = require "colour"
local brush = require "brush"
local common = require "common"

local NoteLayer = Class {
    BLOCK_SIZE = 256,
}

function NoteLayer.default()
    local layer = NoteLayer()
    local defaultnotes = {
[[
welcome to kooltool
please have fun]],
[[
in pixel mode (q) draw you can 
create a set of beautiful tiles
as building blocks for a world]],
[[
in tile mode (w) you can build your
own landscape from your tiles]],
[[
in note mode (e) you can keep notes
and make annotations on your project
for planning and commentary]],
[[
press alt to copy the tile or
colour currently under the mouse]],
[[
you can drag notes
around in note mode]],
[[
you can delete notes with
right click in note mode]],
[[
hold the middle click and drag
to move around the world]],
[[
use the mouse wheel
to zoom in and out]],
[[
press s to save]],
[[
hold control to erase annotations]],
    }

    for i, note in ipairs(defaultnotes) do
        local x = love.math.random(256-128, 512-128)
        local y = (i - 1) * (512 / #defaultnotes) + 32
        layer:addNotebox(Notebox(layer, x, y, note))
    end

    return layer
end

function NoteLayer:deserialise(data, saves)
    local noteboxes = data.notes

    for i, notebox in pairs(noteboxes) do
        local notebox = Notebox(self, unpack(notebox))
        self:addNotebox(notebox)
    end

    local blocks = data.blocks
    local annotations = saves .. "/annotations"

    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(255, 255, 255, 255)
    for y, row in pairs(blocks) do
        for x, path in pairs(row) do
            local image = love.graphics.newImage(annotations .. "/" .. path)
            local block = common.canvasFromImage(image)

            self.blocks:set(block, tonumber(x), tonumber(y))
        end
    end
    love.graphics.setBlendMode("alpha")
end

function NoteLayer:serialise(saves)
    local noteboxes = {}

    for notebox in pairs(self.noteboxes) do
        table.insert(noteboxes, notebox:serialise())
    end

    local annotations = saves .. "/annotations"
    love.filesystem.createDirectory(annotations)

    local blocks = {}

    for block, x, y in self.blocks:items() do
        local file = x .. "," .. y .. ".png"

        blocks[y] = blocks[y] or {}
        blocks[y][x] = file

        block:getImageData():encode(annotations .. "/" .. file)
    end

    return {
        notes = noteboxes,
        blocks = blocks,
    }
end

function NoteLayer:init()
    self.noteboxes = {}
    self.blocks = SparseGrid(self.BLOCK_SIZE)

    self.collider = Collider(256)

    self.collider:setCallbacks(function(dt, shape_one, shape_two, dx, dy)
        shape_one.notebox:move( dx/2,  dy/2)
        shape_two.notebox:move(-dx/2, -dy/2)
    end)

    self.input_state = {}
end

function NoteLayer:update(dt)
    for i=1,5 do
        self.collider:update(dt * 0.2)
    end

    if self.input_state.drag then
        local notebox, dx, dy = unpack(self.input_state.drag)
        local mx, my = CAMERA:mousepos()

        notebox:moveTo(mx*2 + dx, my*2 + dy)
    elseif self.input_state.draw then
        local mx, my = CAMERA:mousepos()
        mx, my = math.floor(mx), math.floor(my)
        local dx, dy = unpack(self.input_state.draw)
        dx, dy = math.floor(dx), math.floor(dy)

        if not love.keyboard.isDown("lctrl") then
            local brush, ox, oy = brush.line(dx, dy, mx, my, 2, {255, 255, 255, 255})
            self:applyBrush(ox, oy, brush)
        else
            local brush, ox, oy = brush.line(dx, dy, mx, my, 7)
            self:eraseBrush(ox, oy, brush)
        end

        self.input_state.draw = {mx, my}
    end

    for notebox in pairs(self.noteboxes) do
        if notebox.text == "" and notebox ~= self.input_state.selected then
            self:removeNotebox(notebox)
        end
    end
end

function NoteLayer:draw()
    love.graphics.setBlendMode("alpha")
    
    love.graphics.setColor(colour.random(128, 255))

    for block, x, y in self.blocks:items() do
        love.graphics.draw(block, 
                           x * self.BLOCK_SIZE * 2, 
                           y * self.BLOCK_SIZE * 2,
                           0, 2, 2)
    end

    love.graphics.setColor(255, 255, 255, 255)

    for notebox in pairs(self.noteboxes) do
        notebox:draw()
    end
end

function NoteLayer:addNotebox(notebox)
    self.noteboxes[notebox] = true
    self.collider:addShape(notebox.shape)
end

function NoteLayer:removeNotebox(notebox)
    self.noteboxes[notebox] = nil
    self.collider:remove(notebox.shape)
end

function NoteLayer:swapShapes(old, new)
    self.collider:remove(old)
    self.collider:addShape(new)
end

function NoteLayer:applyBrush(bx, by, brush)
    local gx, gy, tx, ty = self.blocks:gridCoords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile
    local bw, bh = brush:getDimensions()
    local size = self.BLOCK_SIZE

    local gw, gh = math.ceil((bw + tx) / size), math.ceil((bh + ty) / size)
    local quad = love.graphics.newQuad(0, 0, size, size, bw, bh)

    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local block = self.blocks:get(gx + x, gy + y)
            quad:setViewport(-tx + x * size, -ty + y * size, size, size)

            if not block then
                block = love.graphics.newCanvas(self.BLOCK_SIZE, self.BLOCK_SIZE)
                self.blocks:set(block, gx + x, gy + y)
            end

            block:renderTo(function()
                love.graphics.draw(brush, quad, 0, 0)
            end)
        end
    end
end

function NoteLayer:eraseBrush(bx, by, brush)
    local gx, gy, tx, ty = self.blocks:gridCoords(bx, by)
    bx, by = math.floor(bx), math.floor(by)

    -- split canvas into quads
    -- draw each quad to the corresponding tile
    local bw, bh = brush:getDimensions()
    local size = self.BLOCK_SIZE

    local gw, gh = math.ceil((bw + tx) / size), math.ceil((bh + ty) / size)
    local quad = love.graphics.newQuad(0, 0, size, size, bw, bh)

    love.graphics.setBlendMode("multiplicative")
    love.graphics.setColor(255, 255, 255, 255)
    for y=0,gh-1 do
        for x=0,gw-1 do
            local block = self.blocks:get(gx + x, gy + y)
            quad:setViewport(-tx + x * size, -ty + y * size, size, size)

            if block then
                block:renderTo(function()
                    love.graphics.draw(brush, quad, 0, 0)
                end)
            end
        end
    end
    love.graphics.setBlendMode("alpha")
end

function NoteLayer:keypressed(key)
    local selected = self.input_state.selected

    if selected then
        if key == "escape" then
            self.input_state.selected = nil
        else
            selected:keypressed(key)
        end

        return true
    end

    return false
end

function NoteLayer:textinput(text)
    local selected = self.input_state.selected

    if selected then
        selected:textinput(text)
        return true
    end

    return false
end

function NoteLayer:mousepressed(x, y, button)
    local shape = self.collider:shapesAt(x, y)[1]
    local notebox = shape and shape.notebox

    if button == "l" then
        if notebox then
            local dx, dy = notebox.x - x, notebox.y - y
        
            self.input_state.drag = {notebox, dx, dy}
            self.input_state.selected = notebox
        else
            self.input_state.draw = {x / 2, y / 2}
            self.input_state.selected = nil
        end

        return true
    elseif button == "r" then
        if notebox then
            self:removeNotebox(notebox)
            self.input_state.selected = nil
        else
            notebox = Notebox(self, x, y)
            self:addNotebox(notebox)
            self.input_state.selected = notebox
        end

        return true
    end

    return false
end

function NoteLayer:mousereleased(x, y, button)
    if button == "l" then
        self.input_state.drag = nil
        self.input_state.draw = nil
    end
end

return NoteLayer

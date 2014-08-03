local Class = require "hump.class"
local Collider = require "collider"
local SparseGrid = require "sparsegrid"
local EditMode = require "editmode"
local Notebox = require "notebox"

local colour = require "colour"
local brush = require "brush"
local common = require "common"

local Annotate = Class { __includes = EditMode, name = "annotate project" }

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
hold the middle click and drag
to move around the world]],
[[
use the mouse wheel
to zoom in and out]],
[[
in tile edit mode (q) draw you can 
create a set of beautiful tiles as
building blocks for a world]],
[[
in tile placement mode (w) you can build
your own landscape from your tiles]],
[[
in annotate project mode (e) you can keep
notes and make annotations on your project
for planning and developer commentary]],
[[
press alt and click to copy the tile
or colour currently under the mouse]],
[[
in annotate project mode right click
to add and remove text notes]],
[[
drag or select notes for editing with left click]],
[[
press f12 to save]],
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

    self.modes = {
        annotate = Annotate(self),
    }
end

function NoteLayer:update(dt)
    for i=1,5 do
        self.collider:update(dt * 0.2)
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

function Annotate:hover(x, y, dt)
    if self.state.drag then
        local notebox, dx, dy = unpack(self.state.drag)

        notebox:moveTo(x*2 + dx, y*2 + dy)
    elseif self.state.draw then
        local dx, dy = unpack(self.state.draw)

        if not love.keyboard.isDown("lctrl") then
            local brush, ox, oy = brush.line(dx, dy, x, y, 2, {255, 255, 255, 255})
            self.layer:applyBrush(ox, oy, brush)
        else
            local brush, ox, oy = brush.line(dx, dy, x, y, 7)
            self.layer:eraseBrush(ox, oy, brush)
        end

        self.state.draw = {x, y}
    end

    for notebox in pairs(self.layer.noteboxes) do
        if notebox.text == "" and notebox ~= self.state.selected then
            self.layer:removeNotebox(notebox)
        end
    end
end

function Annotate:mousepressed(x, y, button)
    local shape = self.layer.collider:shapesAt(x*2, y*2)[1]
    local notebox = shape and shape.notebox

    if button == "l" then
        if notebox then
            local dx, dy = notebox.x - x*2, notebox.y - y*2
        
            self.state.drag = {notebox, dx, dy}
            self.state.selected = notebox
        else
            self.state.draw = {x, y}
            self.state.selected = nil
        end

        return true
    elseif button == "r" then
        if notebox then
            self.layer:removeNotebox(notebox)
            self.state.selected = nil
        else
            notebox = Notebox(self.layer, x*2, y*2)
            self.layer:addNotebox(notebox)
            self.state.selected = notebox
        end

        return true
    end

    return false
end

function Annotate:mousereleased(x, y, button)
    if button == "l" then
        self.state.drag = nil
        self.state.draw = nil
    end
end

function Annotate:keypressed(key)
    local selected = self.state.selected

    if selected then
        if key == "escape" then
            self.state.selected = nil
        else
            selected:keypressed(key)
        end

        return true
    end

    return false
end

function Annotate:textinput(text)
    local selected = self.state.selected

    if selected then
        selected:textinput(text)
        return true
    end

    return false
end

return NoteLayer

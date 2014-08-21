local Class = require "hump.class"
local Collider = require "collider"
local SparseGrid = require "utilities.sparsegrid"
local Notebox = require "notebox"

local colour = require "colour"
local common = require "common"

local AnnotationLayer = Class {
    BLOCK_SIZE = 256,
}

function AnnotationLayer:deserialise(data, saves)
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
            if path ~= "" then
                local image = love.graphics.newImage(annotations .. "/" .. path)
                local block = common.canvasFromImage(image)

                self.blocks:set(block, tonumber(x), tonumber(y))
            end
        end
    end
    love.graphics.setBlendMode("alpha")
end

function AnnotationLayer:serialise(saves)
    local noteboxes = {}

    for notebox in pairs(self.noteboxes) do
        table.insert(noteboxes, notebox:serialise())
    end

    local annotations = saves .. "/annotations"
    love.filesystem.createDirectory(annotations)

    local blocks = {[0]={[0]=""}}

    for block, x, y in self.blocks:items() do
        local file = x .. "," .. y .. ".png"

        blocks[y] = blocks[y] or {[0]=""}
        blocks[y][x] = file

        block:getImageData():encode(annotations .. "/" .. file)
    end

    return {
        notes = noteboxes,
        blocks = blocks,
    }
end

function AnnotationLayer:init()
    self.noteboxes = {}
    self.blocks = SparseGrid(self.BLOCK_SIZE)

    self.collider = Collider(256)

    self.collider:setCallbacks(function(dt, shape_one, shape_two, dx, dy)
        local notebox_one, notebox_two = shape_one.notebox, shape_two.notebox

        PROJECT.history:push(function()
            notebox_one:move( dx/2,  dy/2)
            notebox_two:move(-dx/2, -dy/2)
        end, function()
            notebox_one:move(-dx/2, -dy/2)
            notebox_two:move( dx/2,  dy/2)
        end)
    end)
end

function AnnotationLayer:update(dt)
    for i=1,5 do
        self.collider:update(dt * 0.2)
    end
end

function AnnotationLayer:draw()
    love.graphics.setBlendMode("alpha")
    
    love.graphics.setColor(colour.cursor(0))

    for block, x, y in self.blocks:items() do
        love.graphics.draw(block, 
                           x * self.BLOCK_SIZE, 
                           y * self.BLOCK_SIZE,
                           0, 1, 1)
    end

    love.graphics.setColor(255, 255, 255, 255)

    for notebox in pairs(self.noteboxes) do
        notebox:draw(INTERFACE_.tools.type.target == notebox)
    end
end

function AnnotationLayer:objectAt(x, y)
    local shape = self.collider:shapesAt(x, y)[1]
    local notebox = shape and shape.notebox

    return notebox
end

function AnnotationLayer:addNotebox(notebox)
    self.noteboxes[notebox] = true
    self.collider:addShape(notebox.shape)
end

function AnnotationLayer:removeNotebox(notebox)
    self.noteboxes[notebox] = nil
    self.collider:remove(notebox.shape)
end

function AnnotationLayer:swapShapes(old, new)
    self.collider:remove(old)
    self.collider:addShape(new)
end

function AnnotationLayer:applyBrush(bx, by, brush)
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

            brush:apply(block, quad, 0, 0)
        end
    end
end

return AnnotationLayer

local Class = require "hump.class"
local Collider = require "collider"
local SparseGrid = require "utilities.sparsegrid"
local Notebox = require "components.notebox"
local Layer = require "layers.layer"

local colour = require "utilities.colour"
local common = require "utilities.common"

local AnnotationLayer = Class {
    __includes = Layer,
    type = "AnnotationLayer",
    name = "kooltool annotation layer",

    actions = { "mark", "note", },
    tags = { "editor", "annotation", },

    BLOCK_SIZE = 1024,
}

function AnnotationLayer:serialise(resources)
    local noteboxes = {}

    for notebox in pairs(self.children) do
        if notebox.type == "Notebox" then
            table.insert(noteboxes, notebox:serialise())
        end
    end

    local blocks = {[0]={[0]=""}}

    for block, x, y in self.blocks:items() do
        local full, file = resources:file(self, x .. "," .. y .. ".png")

        blocks[y] = blocks[y] or {[0]=""}
        blocks[y][x] = file

        block:getImageData():encode(full)
    end

    return {
        notes = noteboxes,
        blocks = blocks,
    }
end

function AnnotationLayer:deserialise(resources, data)
    for i, data in pairs(data.notes) do
        local notebox = Notebox(self)
        notebox:deserialise(resources, data)
        self:add(notebox)
    end

    for y, row in pairs(data.blocks) do
        for x, path in pairs(row) do
            if path ~= "" then
                local image = love.graphics.newImage(resources:path(path))
                local block = common.canvasFromImage(image)

                self.blocks:set(block, tonumber(x), tonumber(y))
                self.BLOCK_SIZE = image:getWidth()
            end
        end
    end

    self.blocks:SetCellSize(self.BLOCK_SIZE)
end

function AnnotationLayer:init()
    Layer.init(self)

    self.noteboxes = {}
    self.blocks = SparseGrid(self.BLOCK_SIZE)
end

function AnnotationLayer:finalise()
end

function AnnotationLayer:draw(params)
    love.graphics.setBlendMode("alpha")
    
    love.graphics.setColor(colour.cursor(0))

    for block, x, y in self.blocks:items() do
        love.graphics.draw(block, 
                           x * self.BLOCK_SIZE, 
                           y * self.BLOCK_SIZE,
                           0, 1, 1)
    end

    love.graphics.setColor(255, 255, 255, 255)
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

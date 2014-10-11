local Class = require "hump.class"
local common = require "utilities.common"

local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"

local Sprite = Class {
    __includes = Panel,
    name = "Generic Sprite",
}

function Sprite:serialise(saves)
    local file = saves .. "/" .. self.id .. ".png"

    self.canvas:getImageData():encode(file)

    return {
        pivot = self.pivot,
    }
end

function Sprite:deserialise(data, saves)
    local file = saves .. "/" .. self.id .. ".png"

    local px, py = unpack(data.pivot)

    self.canvas = common.loadCanvas(file)
    
    local w, h = self.canvas:getDimensions()

    self.pivot = {px, py}

    self:refresh()
end

function Sprite:init(layer, id)
    self.layer = layer
    self.id = id

    Panel.init(self, { actions = {"draw"}, })
end

function Sprite:blank(w, h)
    local dw, dh = unpack(self.layer.tileset.dimensions)
    w, h = w or dw, h or dh

    self.canvas = love.graphics.newCanvas(w, h)
    self.pivot = {w/2, w/2}
    
    self.canvas:renderTo(function()
        love.graphics.circle("fill", w/2, h/2, 16, 32)
    end)

    self:refresh()
end

function Sprite:draw(x, y, a, s)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0, 0, 255, 255)
    self.shape:draw("fill")

    local w, h = self.canvas:getDimensions()
    local px, py = unpack(self.pivot)

    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(255, 255, 255, 255)

    local px, py = unpack(self.pivot)
    love.graphics.draw(self.canvas, 
                       self.shape.x+px, self.shape.y+py,
                       a or 0,
                       s or 1, s or 1,
                       px, py)

    self:draw_children()
end

function Sprite:refresh()
    local w, h = self.canvas:getDimensions()

    local px, py = unpack(self.pivot)

    self.shape = shapes.Rectangle { x = 0, y = 0,
                                    w = w, h = h, 
                                    pivot = {px, py} }

    self.name = string.format("sprite %s %s", w, h)
end

function Sprite:applyBrush(bx, by, brush, lock)
    local px, py = 0, 0 --unpack(self.pivot)
    bx, by = bx + px, by + py

    if lock then
        local bw, bh = brush:getDimensions()
        local brush_rect = {bx, by, bw, bh}
        local sw, sh = self.canvas:getDimensions()
        local sprite_rect = {0, 0, sw, sh}
        
        local rect = common.expandRectangle(sprite_rect, brush_rect)
        local dx, dy, nw, nh = unpack(rect)

        if dx < 0 or dy < 0 or nw ~= sw or nh ~= sh then
            self.canvas = common.resizeCanvas(self.canvas, nw, nh, -dx, -dy)
            self.pivot = {px - dx, py - dy}
            self:refresh()

            if self.entity then
                self.entity.shape.x = self.entity.shape.x - dx
                self.entity.shape.y = self.entity.shape.y - dy
            end
        end

        if self.entity then
            self.entity.shape.w = nw
            self.entity.shape.h = nh
        end

        bx, by = bx - dx, by - dy
    end

    brush:apply(self.canvas, nil, bx, by)
end

function Sprite:sample(x, y)
    local px, py = unpack(self.pivot)
    return {self.canvas:getPixel(x + px, y + py)}
end

return Sprite

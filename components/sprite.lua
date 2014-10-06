local Class = require "hump.class"
local common = require "utilities.common"

local Sprite = Class {}

function Sprite:serialise(saves)
    local file = saves .. "/" .. self.id .. ".png"

    self.canvas:getImageData():encode(file)

    return {
        pivot = self.pivot,
    }
end

function Sprite:deserialise(data, saves)
    local file = saves .. "/" .. self.id .. ".png"

    self.canvas = common.loadCanvas(file)
    self.pivot = data.pivot

    self:refresh()
end

function Sprite:init(layer, id)
    self.layer = layer
    self.id = id
end

function Sprite:blank(w, h)
    local dw, dh = unpack(self.layer.tileset.dimensions)
    w, h = w or dw, h or dh

    self.canvas = love.graphics.newCanvas(w, h)
    self.pivot = {w/2, h/2}
    self.size = {w, h}
end

function Sprite:draw(x, y, a, s)
    local px, py = unpack(self.pivot)
    love.graphics.draw(self.canvas, x, y, a or 0, s or 1, s or 1, px, py)
end

function Sprite:refresh()
    self.size = {self.canvas:getDimensions()}
end

function Sprite:applyBrush(bx, by, brush, lock)
    local px, py = unpack(self.pivot)
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
            self.size = {nw, nh}
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

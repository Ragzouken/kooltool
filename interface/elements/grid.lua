local Class = require "hump.class"

local Grid = Class {
    padding = {left=2, right=2, top=2, bottom=2},
    spacing = 2,
    slack = "spacing" -- / "padding" / "cells" / "ignore"
}

function Grid:init(params)
    self.shape = params.shape

    self.padding = params.padding or self.padding
    self.spacing = params.spacing or self.spacing
    self.slack   = params.slack   or self.slack

    self:clear()
end

function Grid:clear()
    self.elements = {}
end

function Grid:add(element)
    if self.elements[element] then self:remove(element) end

    local i = #self.elements + 1

    self.elements[element] = i
    self.elements[i] = element
end

function Grid:remove(element)
    local i = self.elements[element]

    if not i then return end

    self.elements[element] = nil
    table.remove(self.elements, i)
end

function Grid:update(dt)
    local cw, ch = 0, 0

    for i, element in ipairs(self.elements) do
        cw = math.max(cw, element.shape.w)
        ch = math.max(ch, element.shape.h)
    end

    local top, bottom = self.padding.top, self.padding.bottom
    local left, right = self.padding.left, self.padding.right
    local spacing = self.spacing

    local width = self.shape.w
    local slack = width - left - right

    local cols = 1

    while cols * cw + (cols - 1) * spacing <= slack do
        cols = cols + 1
    end

    cols = math.max(1, cols - 1)

    -- distribute the left-over space into the spaces
    slack = math.max(0, slack - (cols * cw + (cols - 1) * spacing))       
    spacing = spacing + slack / (cols - 1) 

    for i, element in ipairs(self.elements) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local x = left + cw * col + spacing * col
        local y = top  + ch * row + spacing * row

        element:move_to { anchor = {0, 0}, x = x, y = y }
    end
end

return Grid

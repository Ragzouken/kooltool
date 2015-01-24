local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Grid = Class {
    __includes = Panel,

    padding = {left=2, right=2, top=2, bottom=2},
    spacing = 2,
    slack = "spacing", -- / "padding" / "cells" / "ignore"
    grow = false,
}

function Grid:init(params)
    Panel.init(self, params)

    self.padding = params.padding or self.padding
    self.spacing = params.spacing or self.spacing
    self.slack   = params.slack   or self.slack
    self.grow    = params.grow    or self.grow
end

function Grid:update(dt)
    local cw, ch = 0, 0
    local cells = 0

    for element in self.sorted:upwards() do
        cells = cells + 1
        cw = math.max(cw, element.shape.w)
        ch = math.max(ch, element.shape.h)
    end

    local top    = self.padding.top    or self.padding.default
    local bottom = self.padding.bottom or self.padding.default
    local left   = self.padding.left   or self.padding.default 
    local right  = self.padding.right  or self.padding.default
    local spacing = self.spacing

    local width = self.shape.w
    local slack = width - left - right

    local cols = self:columns(cw)

    -- distribute the left-over space into the spaces
    slack = math.max(0, slack - (cols * cw + (cols - 1) * spacing))       
    spacing = spacing + slack / (cols - 1) 

    local rows = math.ceil(cells / cols)
    
    if self.grow then
        self.shape.h = top + rows * ch + (rows - 1) * spacing + bottom
    end

    local i = 1
    for element in self.sorted:upwards() do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local x = left + cw * col + spacing * col
        local y = top  + ch * row + spacing * row

        element:move_to { anchor = {0, 0}, x = x, y = y }

        i = i + 1
    end

    Panel.update(self, dt)
end

function Grid:columns(cw)
    local top    = self.padding.top    or self.padding.default
    local bottom = self.padding.bottom or self.padding.default
    local left   = self.padding.left   or self.padding.default 
    local right  = self.padding.right  or self.padding.default
    local spacing = self.spacing

    local width = self.shape.w
    local slack = width - left - right

    local cols = 1

    while cols * cw + (cols - 1) * spacing <= slack do
        cols = cols + 1
    end

    cols = math.max(1, cols - 1)

    return cols
end

return Grid

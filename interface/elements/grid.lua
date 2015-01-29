local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Grid = Class {
    __includes = Panel,

    padding = {left=2, right=2, top=2, bottom=2},
    spacing = 2,
    slack = "spacing", -- / "padding" / "cells" / "ignore"
    
    grow = false,
    axis = "vertical",
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

    local cols, spacing = self:fit_cells(cw, self.axis == "vertical" and self.shape.w or self.shape.h, self.spacing, self.padding.default)
    
    if self.axis == "vertical" then
        local rows = math.ceil(cells / cols)
        
        if self.grow then
            self.shape.h = top + rows * ch + (rows - 1) * spacing + bottom
        end
    else
        local rows = math.ceil(cells / cols)
        
        if self.grow then
            self.shape.w = top + rows * cw + (rows - 1) * spacing + bottom
        end
    end

    local i = 1
    for element in self.sorted:upwards() do
        local col, row

        if self.axis == "vertical" then
            col = (i - 1) % cols
            row = math.floor((i - 1) / cols)
        else
            col = math.floor((i - 1) / cols)
            row = (i - 1) % cols
        end

        local x = left + cw * col + spacing * col
        local y = top  + ch * row + spacing * row

        element:move_to { anchor = {0, 0}, x = x, y = y }

        i = i + 1
    end

    Panel.update(self, dt)
end

function Grid:fit_cells(cell_size, container_size, spacing, padding)
    spacing = spacing or self.spacing
    padding = padding or self.padding.default

    local slack = container_size - spacing * 2
    
    local cells = 1

    while cells * cell_size + (cells - 1) * spacing <= slack do
        cells = cells + 1
    end

    cells = math.max(1, cells - 1)

    -- distribute the left-over space into the spaces
    slack = math.max(0, slack - (cells * cell_size + (cells - 1) * spacing))       
    spacing = cells > 1 and spacing + slack / (cells - 1) or 0

    return cells, spacing
end

return Grid

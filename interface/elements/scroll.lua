local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local ScrollPanel = Class {
    __includes = Panel,
    name = "Generic ScrollPanel",

    actions = { "scroll" },

    colours = { fill = {  0,   0,   0,   0},
                line = {255,   0, 255, 255}},

    clip = true,
}

function ScrollPanel:init(params)
    Panel.init(self, params)

    self.sx, self.sy = 0, 0
    self.content = params.content
    self:add(self.content)
end

function ScrollPanel:scroll(vx, vy)
    local dx = math.max(0, self.content.shape.w - self.shape.w)
    local dy = math.max(0, self.content.shape.h - self.shape.h)

    self.sx = math.max(math.min(dx, self.sx + vx), 0)
    self.sy = math.max(math.min(dy, self.sy + vy), 0)

    self.content:move_to { x = -self.sx, y = -self.sy, anchor = {0, 0} }
end

return ScrollPanel

local Class = require "hump.class"
local Collider = require "collider"

local Panel = Class {}

function Panel:init(bounds)
    self.collider = Collider()
    self.children = {}
end

function Panel:draw()
    for child in pairs(self.children) do
        child:draw()
    end
end

function Panel:click(button, x, y)
    for i, shape in ipairs(self.collider:shapesAt(x, y)) do
        if shape.click(x, y, button) then
            return true
        end
    end

    return false
end

function Panel:addChild(panel)
    self.collider:addShape(panel.shape)
    self.children[panel] = true
end

function Panel:removeChild(panel)
    self.collider:remove(panel.shape)
    self.children[panel] = nil
end

return Panel

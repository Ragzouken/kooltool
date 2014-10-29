local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"

local Button = Class {
    __includes = Panel, 
    name = "Generic Button",

    actions = {"press"},
}

function Button:init(params)
    if not params.shape then
        local _, _, w, h = params.icon.quad:getViewport()
        params.shape = shapes.Rectangle { x = params.x, y = params.y,
                                          w = w,        h = h,
                                          anchor = params.anchor}
    end
    
    Panel.init(self, params)
    
    self.icon = params.icon
    self.action = params.action or function() end
end

function Button:draw()
    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(self.colour or {255, 255, 255, 255})
    
    if self.icon and self.icon.image then
        love.graphics.draw(self.icon.image,
                           self.icon.quad,
                           self.shape.x, self.shape.y)
    end
end

function Button:event(event)
    if event.action == "press" then
        self:action(event)
    end
end

return Button

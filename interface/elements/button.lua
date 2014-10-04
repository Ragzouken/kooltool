local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"

local Button = Class { __includes = Panel, }

function Button:init(params)
    local _, _, w, h = params.icon.quad:getViewport()
    
    params.shape = shapes.Rectangle(params.x, params.y, w, h, params.anchor or {-1, -1})
    params.actions = {"press"}
    
    Panel.init(self, params)
    
    self.icon = params.icon
    self.action = params.action
end

function Button:draw()
    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(self.colour or {255, 255, 255, 255})
    
    love.graphics.draw(self.icon.image,
                       self.icon.quad,
                       self.shape:anchor())
end

function Button:event(event)
    if event.action == "press" then
        self:action(event)
    end
end

return Button

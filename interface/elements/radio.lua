local Class = require "hump.class"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"

local Radio = Class { __includes = Button, }

function Radio:init(params)
    Button.init(self, params)
    
    self.group = params.group
end

function Radio:draw()
    Button.draw(self)
    
    if self.group.selected[self] then
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255, 255, 255, 255)
        self.shape:draw("line")
    end
end

function Radio:event(event)
    if event.action == "press" then
        self:action(event)
        self.group:select(self)
    end
end

Radio.Group = Class {}

function Radio.Group:init()
    self.selected = {}
end

function Radio.Group:select(button)
    self.selected = {[button] = true}
end

return Radio

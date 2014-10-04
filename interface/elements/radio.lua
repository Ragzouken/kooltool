local Class = require "hump.class"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"

local colour = require "utilities.colour"

local Radio = Class { __includes = Button, }

function Radio:init(params)
    Button.init(self, params)
    
    self.group = params.group
end

function Radio:draw()
    if self.group.selected[self] then
        self.colour = {colour.cursor(0)}
    else
        self.colour = nil
    end
    
    Button.draw(self)
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

local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local shapes = require "interface.elements.shapes"

local Button = Class {
    __includes = Panel, 
    name = "Generic Button",

    actions = {"press"},

    colours = { fill  = {  0,   0,   0,   0}, 
                line  = {  0,   0,   0,   0},
                image = {255, 255, 255, 255}},
}

function Button.Icon(image, quad)
    local w, h = image:getDimensions()
    
    local icon = {
        image = image,
        quad = quad or love.graphics.newQuad(0, 0, w, h, w, h),
    }

    return icon
end

function Button:init(params)
    if not params.shape and params.image then
        local _, _, w, h = params.image.quad:getViewport()
        params.shape = shapes.Rectangle { w = w, h = h,
                                          anchor = params.anchor }
    end
    
    Panel.init(self, params)

    self.action = params.action or function() end
end

function Button:event(event)
    if event.action == "press" then
        self:action(event)
    end
end

return Button

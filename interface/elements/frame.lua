local Class = require "hump.class"
local Camera = require "hump.camera"
local Panel = require "interface.elements.panel"

local Frame = Class { __includes = Panel, }

function Frame:init(params)
    Panel.init(self, params)

    self.camera = params and params.camera or Camera(128, 128, 2)
end

function Frame:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(self.colours.fill)
    self.shape:draw("fill")
    love.graphics.setColor(self.colours.stroke)
    self.shape:draw("line")

    love.graphics.push()
    love.graphics.translate(self.shape:anchor())
    self.camera:attach()
    
    for child in self.sorted:upwards() do
        if child.active then child:draw() end
    end
       
    self.camera:detach() 
    love.graphics.pop()
end

return Frame

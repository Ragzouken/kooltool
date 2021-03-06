local Class = require "hump.class"
local Camera = require "hump.camera"
local Panel = require "interface.elements.panel"

local Frame = Class {
    __includes = Panel,
    name = "Generic Frame",
    --actions = {"drag"},
}

function Frame:init(params)
    Panel.init(self, params)

    self.camera = params and params.camera or Camera(128, 128, 2)
end

function Frame:target(action, x, y, debug)
    local lx, ly = self.camera:worldCoords(x, y)

    for child in self.sorted:downwards() do
        if child.active then
            local target, x, y = child:target(action, lx, ly, debug)

            if target ~= nil then return target, x, y end
        end
    end

    if self.shape:contains(x, y) then
        if self.actions[action] then
            return self, lx, ly
        elseif self.actions["block"] then
            --return false, lx, ly
        end
    end
end

function Frame:transform(target, x, y)
    if target == self then
        return {x, y}
    end

    local tx, ty = self.camera:worldCoords(x, y)

    for child in self.sorted:downwards() do
        local coords = child:transform(target, math.floor(tx), math.floor(ty))
        
        if coords then return coords end
    end
end

function Frame:draw_tree(params)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    self.camera:attach()
    
    for child in self.sorted:upwards() do
        if child.active then child:draw_tree(params) end
    end
       
    self.camera:detach() 
    love.graphics.pop()
end

function Frame:move_to(params)
    local px, py = unpack(params.pivot)

    self.camera:lookAt((px - params.x) / self.camera.scale,
                       (py - params.y) / self.camera.scale)
end

return Frame

local Class = require "hump.class"
local Tool = require "tools.tool"

local Drag = Class { __includes = Tool, name = "drag", }

function Drag:init(project)
    Tool.init(self)
    
    self.project = project
end

function Drag:grab(object, sx, sy, wx, wy)
    self:enddrag()
    self:startdrag("drag")

    self.drag.object = object
    self.drag.pivot = {object.x - wx, object.y - wy}
end

function Drag:drop()
    if self.drag and not self.drag.object.sprite then
        INTERFACE_.tools.type.target = self.drag.object
    end

    self:enddrag()
end

function Drag:mousepressed(button, sx, sy, wx, wy)
    if self.drag and button == "r" then
        if self.drag.object.sprite then
            self.project.layers.surface:removeEntity(self.drag.object)
        else
            self.project.layers.annotation:removeNotebox(self.drag.object)
        end

        self:drop()

        return true, "end"
    elseif button == "l" then
        local object = self.project:objectAt(wx, wy)
        
        if object then
            self:grab(object, sx, sy, wx, wy)
            
            return true, "begin"
        end

        INTERFACE_.tools.type.target = nil
    end

    return false
end

function Drag:mousedragged(action, screen, world)
    if action == "drag" then
        local px, py = unpack(self.drag.pivot)
        local wx, wy = unpack(world)

        self.drag.object:moveTo(math.floor(wx+px), math.floor(wy+py))
    end
end

function Drag:mousereleased(button, sx, sy, wx, wy)
    if button == "l" then
        self:drop()

        return true, "end"
    end

    return 
end

return Drag

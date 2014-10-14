local Class = require "hump.class"
local Tool = require "tools.tool"

local Drag = Class { __includes = Tool, name = "drag", }

function Drag:init(editor)
    Tool.init(self)
    
    self.editor = editor
end

function Drag:grab(object, sx, sy)
    self:enddrag()
    self:startdrag("drag")

    self.drag.object = object

    self.drag.pivot = self.editor:transform(object, sx, sy)
end

function Drag:drop()
    if self.drag and not self.drag.object.sprite then
        self.target = self.drag.object
    else
        self.target = nil
    end

    self:enddrag()
end


function Drag:cursor(sx, sy)
    if self.drag or self.editor:target("drag", sx, sy) then
        return love.mouse.getSystemCursor("sizeall")
    end
end

function Drag:mousepressed(button, sx, sy, wx, wy)
    if self.drag and button == "r" then
        if self.drag.object.sprite then
            --self.project.layers.surface:removeEntity(self.drag.object)
        else
            --self.project.layers.annotation:removeNotebox(self.drag.object)
        end

        self:drop()

        return true, "end"
    elseif button == "l" then
        local target, x, y = self.editor:target("drag", sx, sy)

        if target then
            self:grab(target, sx, sy)
            
            return true, "begin"
        end

        self.target = nil
    end

    return false
end

function Drag:mousedragged(action, screen, world)
    if action == "drag" then
        -- need to get position of mouse in coord space of draggee's parent
        local wx, wy = unpack(self.editor:transform(self.drag.object.parent, unpack(screen)))

        self.drag.object:move_to { x = wx, y = wy,
                                   pivot = self.drag.pivot }
    end
end

function Drag:mousereleased(button, sx, sy, wx, wy)
    if button == "l" then
        self:drop()

        return true, "end"
    end

    return 
end

function Drag:keypressed(key, sx, sy, wx, wy)
    if self.target then
        if key == "escape" or (key == "return" and love.keyboard.isDown("lshift")) then
            self.target = nil
            return true
        end

        --return self.target:keypressed(key)
    end
end

function Drag:textinput(character)
    if self.target then
        --return self.target:textinput(character)
    end
end

return Drag

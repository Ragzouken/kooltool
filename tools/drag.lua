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

function Drag:drop(object, sx, sy)
    print("huh", object.type)

    if object.type == "Notebox" then
        print("notebox tho")
        local target, x, y = self.editor:target("note", sx, sy)

        if target then
            print("yeah target", target)

            object.layer:removeNotebox(object)
            target:addNotebox(object)
            object:move_to { x = x, y = y, pivot = self.drag.pivot }
        end
    end

    self:enddrag()
end


function Drag:cursor(sx, sy)
    if self.drag or self.editor:target("drag", sx, sy) then
        if self.drag and self.drag.object.border then self.drag.object:border() end

        return love.mouse.getSystemCursor("sizeall")
    end
end

function Drag:mousepressed(button, sx, sy, wx, wy)
    if button == "l" then
        if love.keyboard.isDown("x", "e") then
            local target, x, y = self.editor:target("remove", sx, sy)

            if target then
                target:remove()
                self.editor.focus = nil
            end
        else
            local target, x, y = self.editor:target("drag", sx, sy)

            if target then
                self:grab(target, sx, sy)
                
                return true, "begin"
            end
        end

        self:enddrag()
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
        if self.drag then self:drop(self.drag.object, sx, sy) end

        return true, "end"
    end
end

return Drag

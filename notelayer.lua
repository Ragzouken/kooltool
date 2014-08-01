local Class = require "hump.class"
local Collider = require "collider"
local Notebox = require "notebox"

local NoteLayer = Class {}

function NoteLayer:deserialise(data)
    local noteboxes = data[1]

    for i, notebox in pairs(noteboxes) do
        local notebox = Notebox(self, unpack(notebox))
        self:addNotebox(notebox)
    end
end

function NoteLayer:serialise()
    local noteboxes = {}

    for notebox in pairs(self.noteboxes) do
        table.insert(noteboxes, notebox:serialise())
    end

    return {noteboxes}
end

function NoteLayer:init()
    self.noteboxes = {}

    self.collider = Collider(256)

    self.collider:setCallbacks(function(dt, shape_one, shape_two, dx, dy)
        shape_one.notebox:move( dx/2,  dy/2)
        shape_two.notebox:move(-dx/2, -dy/2)
    end)

    self.input_state = {}
end

function NoteLayer:update(dt)
    self.collider:update(dt)

    if self.input_state.drag then
        local notebox, dx, dy = unpack(self.input_state.drag)
        local mx, my = CAMERA:mousepos()

        notebox:moveTo(mx*2 + dx, my*2 + dy)
    end

    for notebox in pairs(self.noteboxes) do
        if notebox.text == "" and notebox ~= self.input_state.selected then
            self:removeNotebox(notebox)
        end
    end
end

function NoteLayer:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)

    for notebox in pairs(self.noteboxes) do
        notebox:draw()
    end
end

function NoteLayer:addNotebox(notebox)
    self.noteboxes[notebox] = true
    self.collider:addShape(notebox.shape)
end

function NoteLayer:removeNotebox(notebox)
    self.noteboxes[notebox] = nil
    self.collider:remove(notebox.shape)
end

function NoteLayer:swapShapes(old, new)
    self.collider:remove(old)
    self.collider:addShape(new)
end

function NoteLayer:keypressed(key)
    local selected = self.input_state.selected

    if selected then selected:keypressed(key) end
end

function NoteLayer:textinput(text)
    local selected = self.input_state.selected

    if selected then selected:textinput(text) end
end

function NoteLayer:mousepressed(x, y, button)
    local shape = self.collider:shapesAt(x, y)[1]
    local notebox = shape and shape.notebox

    if button == "l" then
        local dx, dy = 0, 0

        if notebox then
            dx, dy = notebox.x - x, notebox.y - y
        else
            notebox = Notebox(self, x, y)
            self:addNotebox(notebox)
        end

        self.input_state.drag = {notebox, dx, dy}
        self.input_state.selected = notebox
    elseif button == "r" and notebox then
        self:removeNotebox(notebox)
    end
end

function NoteLayer:mousereleased(x, y, button)
    if button == "l" then
        self.input_state.drag = nil
    end
end

return NoteLayer

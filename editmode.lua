local Class = require "hump.class"

local EditMode = Class { name = "[mode name]", }

function EditMode:init(layer, name)
    self.layer = layer
    self.state = {}
end

function EditMode:update(dt)
end

function EditMode:draw(x, y)
end

function EditMode:focus()
end

function EditMode:defocus()
    self.state = {}
end

function EditMode:hover(x, y, dt)
end

function EditMode:keypressed(key, isrepeat)
end

function EditMode:keyreleased(key)
end

function EditMode:textinput(text)
end

function EditMode:mousepressed(x, y, button)
end

function EditMode:mousereleased(x, y, button)
end

return EditMode

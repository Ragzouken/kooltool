local Class = require "hump.class"

local Button = Class {}

function Button:init(rect, click)
    self.rect = rect
    self.click = click or function() end
end

function Button:draw()
end

function Button:click(x, y)
end

return {
    Button = Button,
}

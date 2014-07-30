local Class = require "hump.class"

local Notebox = Class {}

function Notebox:init(x, y, text)
    self.x, self.y = x, y
    self.text = text or ""
end

function Notebox:draw()
end

return Notebox

local Class = require "hump.class"
local Mouse = require "actions.mouse"

local Pan = Class { __includes = Mouse, }

function Pan:pressed(button, sx, sy, wx, wy)
    self.drag.camera = {CAMERA.x, CAMERA.y}
end

function Pan:dragged(sx1, sy1, sx2, sy2)
    local cx, cy = unpack(self.drag.camera)
    local ox, oy = unpack(self.drag.points[1])
    local dx, dy = sx2 - ox, sy2 - oy
    local s = CAMERA.scale

    CAMERA:lookAt(cx - dx / s, cy - dy / s)
end

function Pan:released(button, sx, sy, wx, wy)
end

return Pan

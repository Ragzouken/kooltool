local Class = require "hump.class"

local Mouse = Class {}

function Mouse:init(finish)
    self.finish = finish
end

function Mouse:update(dt, sx, sy, wx, wy)
    if self.drag then
        local lx, ly = unpack(self.drag.points[#self.drag.points])

        table.insert(self.drag.points, {sx, sy})

        self:dragged(lx, ly, sx, sy)
    end
end

function Mouse:mousepressed(button, sx, sy, wx, wy)
    self.drag = {
        points={{sx, sy}},
        button=button,
    }

    self:pressed(button, sx, sy, wx, wy)
end

function Mouse:mousereleased(button, sx, sy, wx, wy)
    self.drag = nil
    self:released(button, sx, sy, wx, wy)
    self.finish()
end

function Mouse:pressed(button, sx, sy, wx, wy)
    print("pressed", sx, sy, button)
end

function Mouse:dragged(x1, y1, x2, y2)
    print("dragged", x1, y1, x2, y2)
end

function Mouse:released(button, sx, sy, wx, wy)
    print("released", sx, sy, button)
end

return Mouse

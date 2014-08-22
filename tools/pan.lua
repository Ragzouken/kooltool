local Class = require "hump.class"
local Tool = require "tools.tool"

local Pan = Class { __includes = Tool, name == "pan", }

function Pan:init(camera)
    Tool.init(self)

    self.camera = camera
end

function Pan:zoomin(wx, wy)
    if self.tween then self.timer:cancel(self.tween) end

    ZOOM = math.min(ZOOM * 2, 16)
    
    local dx, dy, dz = self.camera.x - wx, self.camera.y - wy, ZOOM - self.camera.scale
    local oscale = self.camera.scale
    local factor = ZOOM / self.camera.scale
    local t = 0

    self.tween = self.timer:do_for(0.25, function(dt)
        t = t + dt
        local u = t / 0.25
        local du = factor - 1

        self.camera.scale = oscale*factor - (1 - u) * dz
        self.camera:lookAt(wx + dx / (1 + du*u), wy + dy / (1 + du*u))
    end, nil, "in-quad")
end

function Pan:zoomout(wx, wy)
    if self.tween then self.timer:cancel(self.tween) end

    ZOOM = math.max(ZOOM / 2, 1 / 16)

    self.tween = self.timer:tween(0.25, self.camera, {scale = ZOOM}, "out-quad")
end

function Pan:mousepressed(button, sx, sy, wx, wy)
    if love.keyboard.isDown("tab") then
        if button == "l" then self:zoomin(wx, wy) return true end
        if button == "r" then self:zoomout(wx, wy) return true end
    elseif button == "r" then
        self:startdrag("pan")
        self.drag.camera = {self.camera.x, self.camera.y}
        self.drag.dx, self.drag.dy = 0, 0

        return true, "begin"
    elseif button == "wu" then
        self:zoomin(wx, wy)

        return true
    elseif button == "wd" then
        self:zoomout(wx, wy)
        
        return true
    end

    return true
end

function Pan:mousedragged(action, screen, world)
    if action == "pan" then
        local cx, cy = unpack(self.drag.camera)
        --local s = self.camera.scale

        local _, _, swx, swy = unpack(screen)
        self.drag.dx = self.drag.dx + swx / self.camera.scale
        self.drag.dy = self.drag.dy + swy / self.camera.scale

        self.camera:lookAt(cx - self.drag.dx, cy - self.drag.dy)
    end
end

function Pan:mousereleased(button, sx, sy, wx, wy)
    if button == "r" and self.drag then
        self:enddrag()

        return true, "end"
    end
end

return Pan

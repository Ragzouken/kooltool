local Class = require "hump.class"
local Tool = require "tools.tool"

local Pan = Class { __includes = Tool, name = "pan", }

function Pan:init(camera)
    Tool.init(self)

    self.camera = camera
    self.zoom = 22
    self.camera.scale = zoom_from_level(self.zoom)
end

local zoom_levels = 32

function mix(a, b, u)
    return a * (1 - u) + b * u
end

function zoom_from_level(level)
    local u = level / (zoom_levels - 1)

    u = math.pow(u, 8)

    return mix(32, 1 / 16, 1 - u)
end

local zooms = 1 / 3

function Pan:zoomin(wx, wy)
    if self.tween then self.timer:cancel(self.tween) end

    self.zoom = math.min(self.zoom + 1, zoom_levels - 1)
    
    local scale = zoom_from_level(self.zoom)
    local dx, dy, dz = self.camera.x - wx, self.camera.y - wy, scale - self.camera.scale
    local oscale = self.camera.scale
    local factor = scale / self.camera.scale
    local t = 0

    self.tween = self.timer:do_for(zooms, function(dt)
        t = math.min(t + dt, zooms)
        local u = t / zooms
        local du = factor - 1

        self.camera.scale = oscale*factor - (1 - u) * dz
        self.camera:lookAt(wx + dx / (1 + du*u), wy + dy / (1 + du*u))

        if self.camera.scale % 1 == 0 then
            self.camera:lookAt(math.floor(self.camera.x), math.floor(self.camera.y))
        end
    end, nil, "in-quad")
end

function Pan:zoomout(wx, wy)
    if self.tween then self.timer:cancel(self.tween) end

    self.zoom = math.max(self.zoom - 1, 0)
    
    local scale = zoom_from_level(self.zoom)
    local dx, dy, dz = self.camera.x - wx, self.camera.y - wy, scale - self.camera.scale
    local oscale = self.camera.scale
    local factor = scale / self.camera.scale
    local t = 0

    self.tween = self.timer:do_for(zooms, function(dt)
        t = math.min(t + dt, zooms)
        local u = t / zooms
        local du = factor - 1

        self.camera.scale = oscale*factor - (1 - u) * dz
        --self.camera:lookAt(wx + dx / (1 + du*u), wy + dy / (1 + du*u))

        if self.camera.scale % 1 == 0 then
            self.camera:lookAt(math.floor(self.camera.x), math.floor(self.camera.y))
        end
    end, nil, "in-quad")
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

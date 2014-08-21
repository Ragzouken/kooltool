local Class = require "hump.class"
local Timer = require "hump.timer"

local Tool = Class {}

function Tool:init()
    self.timer = Timer()
    self.mouse = {0, 0, 0, 0}
    self.state = {}
end

function Tool:update(dt, sx, sy, wx, wy)
    self.timer:update(dt)
    self.mouse = {sx, sy, wx, wy}

    if self.drag then
        local tsdx, tsdy = unpack(self.drag.screen_delta)
        local twdx, twdy = unpack(self.drag.world_delta)
        local sdx, sdy, wdx, wdy = 0, 0, 0, 0

        if #self.drag > 0 then
            local last = self.drag[#self.drag]
            local osx, osy = unpack(last.screen)
            local owx, owy = unpack(last.world)
            
            sdx, sdy = sx - osx, sy - osy
            wdx, wdy = wx - owx, wy - owy
        end

        self.drag.screen_delta = {tsdx + sdx, tsdy + sdy}
        self.drag.world_delta = {twdx + wdx, twdy + wdy}

        local screen = {sx, sy, sdx, sdy}
        local world = {wx, wy, wdx, wdy}

        table.insert(self.drag, {
            screen = screen,
            world = world, 
        })

        self:mousedragged(self.drag.action, screen, world)
    end
end

function Tool:cursor(sx, sy, wx, wy)
end

function Tool:mousepressed(button, sx, sy, wx, wy)
    return false, false
end

function Tool:mousereleased(button, sx, sy, wx, wy)
    return false, false
end

function Tool:mousedragged(action, screen, world)
end

function Tool:keypressed(key, sx, sy, wx, wy)
    return false
end

function Tool:keyreleased(key, sx, sy, wx, wy)
    return false
end

function Tool:textinput(character)
    return false
end

function Tool:startdrag(action)
    self.drag = {
        action = action,
        screen_delta = {0, 0},
        world_delta = {0, 0},
    }
end

function Tool:enddrag()
    self.drag = nil
end

return Tool

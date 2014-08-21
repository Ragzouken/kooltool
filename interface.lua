local Class = require "hump.class"

local tools = require "tools"

local Interface = Class {}

function Interface:init(project)
    self.panes = {}
    
    self.action = nil
    self.active = nil

    self.tools = {
        pan = tools.Pan(CAMERA),
        drag = tools.Drag(project),
        draw = tools.Draw(project, PALETTE.colours[3]),
        tile = tools.Tile(project, TILE),
        wall = tools.Wall(project),
        marker = tools.Marker(project),
        type = tools.Type(project),
    }

    self.global = {
        self.tools.type,
        self.tools.pan,
        self.tools.drag,
    }
end

function Interface:update(dt, sx, sy, wx, wy)
    for name, tool in pairs(self.tools) do
        tool:update(dt, sx, sy, wx, wy)
    end
end

function Interface:draw()
end

function Interface:cursor(sx, sy, wx, wy)
    local function cursor(tool)
        local cursor = tool:cursor(sx, sy, wx, wy)

        if cursor then
            love.window.setCursor(cursor)
            return true
        end

        return false
    end

    if self.action and cursor(self.action) then return end
    if self.active and cursor(self.active) then return end

    for name, tool in pairs(self.global) do
        if cursor(tool) then return end
    end
end

function Interface:input(callback, ...)
    local function input(tool, ...)
        local block, change = tool[callback](tool, ...)

        if tool == self.action and change == "end" then
            self.action = nil
        elseif not self.action and change == "begin" then
            self.action = tool
        end
        
        if block then
            return true
        else
            return false
        end
    end

    if self.action and input(self.action, ...) then return true end
    if self.active and input(self.active, ...) then return true end

    for i, tool in ipairs(self.global) do
        if input(tool, ...) then return true end
    end

    return false
end

return Interface

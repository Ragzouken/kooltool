local Class = require "hump.class"
local shapes = require "interface.elements.shapes"

local Panel = Class {
    DEBUG = false,
    actions = {},
}

function Panel:init(params)
    self.depth = params.depth or 0
    self.shape = params.shape or shapes.Plane(0, 0)
    self.actions = params.actions or {}
    
    for i, action in ipairs(self.actions) do
        self.actions[action] = true
    end
    
    self.visible = true
    self.children = {}
    
    self:resort()
end

function Panel:add(panel)
    self.children[panel] = true
    self:resort()
end

function Panel:remove(panel)
    self.children[panel] = false
    self:resort()
end

local function forwards(table)
    return coroutine.wrap(function()
        for i=1,#table do
            coroutine.yield(table[i])
        end
    end)
end

local function backwards(table)
    return coroutine.wrap(function()
        for i=#table,1,-1 do
            coroutine.yield(table[i])
        end
    end)
end

function Panel:resort()
    self.sorted = {
        upwards   = forwards,
        downwards = backwards,
    }
    
    for child in pairs(self.children) do
        table.insert(self.sorted, child)
    end
    
    table.sort(self.sorted, function (a, b) return a.depth > b.depth end)
end

function Panel:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 0, 255, 64)
    if self.boing then love.graphics.setColor(0, 255, 0, 255) end
    self.shape:draw("fill")
    love.graphics.setColor(255, 0, 255, 255)
    self.shape:draw("line")

    love.graphics.push()
    love.graphics.translate(self.shape:anchor())
    
    for child in self.sorted:upwards() do
        if child.visible then child:draw() end
    end
        
    love.graphics.pop()
end

function Panel:target(action, x, y)
    if self.actions[action] and self.shape:contains(x, y) then
        return self
    end
    
    local ax, ay = self.shape:anchor()
    x = x - ax
    y = y - ay
    
    for child in self.sorted:downwards() do
        local target = child:target(action, x, y)
        
        if target then return target end
    end
end

return Panel

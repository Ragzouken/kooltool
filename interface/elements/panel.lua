local Class = require "hump.class"
local shapes = require "interface.elements.shapes"

local Panel = Class {
    DEBUG = false,
    actions = {},
}

function Panel:init(params)
    params = params or {}
    
    self.depth = params.depth or 0
    self.shape = params.shape or shapes.Plane(0, 0)
    self.actions = params.actions or {}
    self.colours = params.colours or {stroke = {255, 0, 255, 255}, 
                                      fill   = {255, 0, 255,  64}}
    
    for i, action in ipairs(self.actions) do
        self.actions[action] = true
    end
    
    self.active = true
    self.children = {}

    self:resort()
end

function Panel:add(panel, depth)
    self.children[panel] = depth or panel.depth or 0
    self:resort()
end

function Panel:remove(panel)
    self.children[panel] = nil
    self:resort()
end

function Panel:clear()
    local children = self.children
    
    self.children = {}
    self:resort()
    
    return children
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
    
    local function depth(a, b)
        return self.children[a] > self.children[b]
    end

    table.sort(self.sorted, depth)
end

function Panel:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(self.colours.fill)
    self.shape:draw("fill")
    love.graphics.setColor(self.colours.stroke)
    self.shape:draw("line")

    love.graphics.push()
    love.graphics.translate(self.shape:anchor())
    
    for child in self.sorted:upwards() do
        if child.active then child:draw() end
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
        if child.active then
            local target = child:target(action, x, y)
            
            if target then return target end
        end
    end
end

return Panel

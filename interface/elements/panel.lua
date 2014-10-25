local Class = require "hump.class"
local shapes = require "interface.elements.shapes"

local Panel = Class {
    DEBUG = false,
    name = "Generic Panel",

    actions = {},

    colours = {stroke = {255, 0, 255, 255},
               fill   = {255, 0, 255,  64}},

    clip = false,
}

function Panel:init(params)
    params = params or {}
    
    self.name = params.name or self.name
    self.depth = params.depth or 0
    self.shape = params.shape or shapes.Plane {x = 0, y = 0}
    self.actions = params.actions or self.actions
    self.colours = params.colours or self.colours
    
    self.clip = params.clip or self.clip

    for i, action in ipairs(self.actions) do
        self.actions[action] = true
    end
    
    self.active = true
    self.children = {}

    self:resort()
end

function Panel:print(depth)
    depth = depth or 0

    print(string.rep("  ", depth) .. self.name)

    for child in self.sorted:upwards() do
        child:print(depth + 1)
    end
end

function Panel:add(panel, depth)
    assert(panel)

    if panel.parent then panel.parent:remove(panel) end
    panel.parent = self
    self.children[panel] = depth or panel.depth or 0
    self:resort()
end

function Panel:remove(panel)
    panel.parent = nil
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

    self:draw_children()
end

function Panel:draw_children()
    love.graphics.push()
    love.graphics.translate(self.shape.x, self.shape.y)

    --[[
    if self.clip and self.shape then
        love.graphics.setStencil(function self.shape:draw("fill") end)
    end
    ]]

    for child in self.sorted:upwards() do
        if child.active then child:draw() end
    end
       
    love.graphics.setStencil()

    love.graphics.pop()
end

--[[ 
given coordinates in parent space, return the first panel that supports the
desired action, along with the coordinates of the hit in it's local coordinates

TODO: maybe track the whole transform chain ffs
--]]
function Panel:target(action, x, y, debug)    
    local ax, ay = self.shape.x, self.shape.y
    local lx, ly = x - ax, y - ay

    for child in self.sorted:downwards() do
        if child.active then
            local target, x, y = child:target(action, lx, ly, debug)

            if target ~= nil then return target, x, y end
        end
    end

    if self.shape:contains(x, y) then
        if self.actions[action] then
            return self, lx, ly
        elseif self.actions["block"] then
            --return false, lx, ly
        end
    end
end

function Panel:transform(target, x, y)
    local ax, ay = self.shape.x, self.shape.y
    local lx, ly = x - ax, y - ay

    if target == self then
        return {lx, ly}
    end

    for child in self.sorted:downwards() do
        local coords = child:transform(target, lx, ly)
        
        if coords then return coords end
    end
end

function Panel:move_to(params)
    self.shape:move_to(params)
end

return Panel

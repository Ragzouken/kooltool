local Class = require "hump.class"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"

local function flattened(base, layer)
    local flat = {}

    for k, v in pairs(base) do
        flat[k] = v
    end

    for k, v in pairs(layer or {}) do
        flat[k] = v
    end

    return flat
end

local Panel = Class {
    DEBUG = false,
    name = "Generic Panel",

    actions = {"tooltip"},

    colours = {line  = {255,   0, 255, 255},
               fill  = {255,   0, 255,  64},
               image = {255, 255, 255, 255}},

    COLOURS = {
        black = {
            fill  = {  0,   0,   0, 255},
            line  = {  0,   0,   0,   0},
            image = {255, 255, 255, 255},
        },

        transparent = {
            fill  = {  0,   0,   0,   0},
            line  = {  0,   0,   0,   0},
            image = {255, 255, 255, 255},
        },
    },

    pointer = love.graphics.newImage("images/pointer.png"),
    tooltip = "",

    clip = false,
}

function Panel.common_ancestor(a, b)
    local found = {}
    local ancestor

    local chain_a = {a}
    local chain_b = {b}

    while a or b do
        if a then
            if found[a] then
                ancestor = a
                break
            else
                found[a] = true
                a = a.parent
            end
        end

        if b then
            if found[b] then
                ancestor = b
                break
            else
                found[b] = true
                b = b.parent
            end
        end
    end

    if ancestor then
        while chain_a[#chain_a] ~= ancestor do
            table.insert(chain_a, chain_a[#chain_a].parent)
        end

        while chain_b[#chain_b] ~= ancestor do
            table.insert(chain_b, chain_b[#chain_b].parent)
        end
    end

    return ancestor, chain_a, chain_b
end

function Panel:init(params)
    params = params or {}
    
    self.name = params.name or self.name

    self.shape = params.shape or shapes.Plane {x = 0, y = 0}
    
    self.x = params.x or self.shape.x
    self.y = params.y or self.shape.y
    self.depth = params.depth

    self.actions = params.actions or self.actions
    self.colours = flattened(self.colours, params.colours)
    self.image = params.image
    self.tooltip = params.tooltip or self.tooltip

    self.tags = params.tags or self.tags or {}

    for i, action in ipairs(self.actions) do
        self.actions[action] = true
    end

    for i, tag in ipairs(self.tags) do
        self.tags[tag] = true
    end
    
    self.active = true
    self.children = {}
    self.default_depth = 0

    self.highlight = params.highlight or self.highlight

    self:resort()
end

function Panel:print(depth, suffix)
    depth = depth or 0
    suffix = suffix and (" (" .. suffix ..  ")") or "" 

    print(string.rep("  ", depth) .. self.name .. suffix)

    for child in self.sorted:upwards() do
        child:print(depth + 1, self.children[child])
    end
end

function Panel:add(panel, depth)
    local depth = depth or panel.depth or self.default_depth
    self.default_depth = self.default_depth - 1

    if panel.parent then panel.parent:remove(panel) end
    panel.parent = self

    self.children[panel] = depth
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

function Panel:update(dt)
    self.t = self.t or 0
    self.t = self.t + dt

    if self.layout then self.layout:update(dt) end

    for child in self.sorted:downwards() do
        child:update(dt)
    end
end

function Panel:check_filters(filters)
    for i, filter in ipairs(filters.whitelist or {}) do
        if self.tags[filter] then return true end
    end

    for i, filter in ipairs(filters.blacklist or {}) do
        if self.tags[filter] then return false end
    end

    return true
end

function Panel:draw(params)
    local fill = self.colours.fill.highlight and {colour.cursor(0, 255, 0.5)}

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(fill or self.colours.fill)
    self.shape:draw("fill")

    if self.image then
        love.graphics.setBlendMode("premultiplied")
        love.graphics.setColor(self.colours.image)
        love.graphics.draw(self.image.image, self.image.quad,
                           self.shape.x, self.shape.y)
    end
end

function Panel:draw_above(params)
    local width = love.graphics.getLineWidth()
    love.graphics.setLineWidth(3)

    love.graphics.setBlendMode("alpha")
    if self.highlight then
        love.graphics.setColor(colour.cursor(0, 255))
    else
        love.graphics.setColor(self.colours.line)
    end
    self.shape:draw("line")

    if self.source then
        local dx = self.source.x - self.x
        local dy = self.source.y - self.y
        local angle = math.atan2(dy, dx)
        local quart = math.pi * 0.5
        angle = math.floor(angle / quart + 0.5) * quart 

        local dx, dy = math.cos(angle), math.sin(angle)

        local cx = self.shape.x + self.shape.w / 2
        local cy = self.shape.y + self.shape.h / 2
        local x = cx + dx * self.shape.w / 2
        local y = cy + dy * self.shape.h / 2

        local ox, oy = dx < 0.5 and 1 or 0, dy < 0.5 and 1 or 0

        love.graphics.setBlendMode("premultiplied")
        love.graphics.draw(self.pointer, x+ox, y+oy, angle, 1, 1, 1, 15.5)
    end

    love.graphics.setLineWidth(width)
end

function Panel:draw_tree(params)
    if not self:check_filters(params.filters or {}) then return end

    love.graphics.push()
    love.graphics.translate(math.floor(self.x), math.floor(self.y))

    self:draw(params)

    if self.clip then
        love.graphics.setStencil(function() self.shape:draw("fill") end)
    end

    for child in self.sorted:upwards() do
        if child.active then child:draw_tree(params) end
    end

    if self.clip then
        love.graphics.setStencil()
    end

    self:draw_above(params)

    love.graphics.pop()
end

--[[ 
given coordinates in parent space, return the first panel that supports the
desired action, along with the coordinates of the hit in it's local coordinates

TODO: maybe track the whole transform chain ffs
--]]
function Panel:target(action, x, y, debug)
    local lx, ly = x - self.x, y - self.y

    if self.clip and not self.shape:contains(lx, ly) then return end

    for child in self.sorted:downwards() do
        if child.active then
            local target, x, y = child:target(action, lx, ly, debug)

            if target ~= nil then return target, x, y end
        end
    end

    if self.shape:contains(lx, ly) then
        if self.actions[action] or action == "tooltip" then
            return self, lx, ly
        elseif self.actions["block"] then
            --return false, lx, ly
        end
    end
end

function Panel:transform(target, x, y)
    local lx, ly = x - self.x, y - self.y

    if target == self then
        return {lx, ly}
    end

    for child in self.sorted:downwards() do
        local coords = child:transform(target, lx, ly)
        
        if coords then return coords end
    end
end

function Panel:move_to(params)
    local dx, dy = 0, 0

    if self.shape and (params.anchor or params.pivot) then
        dx, dy = self.shape:coords(params)
    end

    self.x, self.y = params.x - dx, params.y - dy
end

return Panel

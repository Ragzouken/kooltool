local Class = require "hump.class"

local Interface = Class {
    DEBUG = false,
}

function Interface:init()
    self.panels = {}
    
    self.focus = nil
end

function Interface:add(panel)
    self.panels[panel] = true
end

function Interface:remove(panel)
    self.panels[panel] = false
    
    if self.focus == panel then self.focus = nil end
end

function Interface:hide(panel)
    panel.visible = false
    
    if self.focus == panel then self.focus = nil end
end

function Interface:draw()
    local panels = {}
    
    for panel in pairs(self.panels) do
        table.insert(panels, panel)
    end
    
    table.sort(panels, function (a, b) return a.depth > b.depth end)
    
    for i, panel in ipairs(panels) do
        if panel.visible then panel:draw() end
    end
end

return Interface

local Class = require "hump.class"
local Grid = require "interface.elements.grid"
local Button = require "interface.elements.button"

local Event = require "utilities.event"

local TabBar = Class {
    __includes = Grid,
    name = "generic tab bar",
}

function TabBar:init(params)
    Grid.init(self, params)

    self.tabs = {}

    for i, tab in ipairs(params.tabs) do
        local button = Button {
            image = tab.icon,
            action = function() self:select(tab.name) end,
            tooltip = tab.tooltip,
        }

        self.tabs[tab.name] = {button, tab.panel}
        self:add(button)
    end

    self.selected = Event()
end

function TabBar:select(selected)
    for name, tab in pairs(self.tabs) do
        local button, panel = unpack(tab)

        local active = name == selected

        panel.active = active
        button.highlight = active
    end

    self.selected:fire(selected)
end

return TabBar

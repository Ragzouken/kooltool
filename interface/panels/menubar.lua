local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"
local Grid = require "interface.elements.grid"

local MenuBar = Class {
    __includes = Grid,

    spacing = 4,
    padding = { default = 4, },

    colours = Panel.COLOURS.black,
    grow = true,
    axis = "horizontal",

    highlight = true,

    icons = {
        menu = Button.Icon(love.graphics.newImage("images/menu.png")),
        play = Button.Icon(love.graphics.newImage("images/play.png")),
        save = Button.Icon(love.graphics.newImage("images/save.png")),
        export = Button.Icon(love.graphics.newImage("images/export.png")),
    },
}

function MenuBar:init(params)
    Panel.init(self, params)

    self.editor = params.editor

    local menu = Button { 
        image = self.icons.menu,
        action = function()
            self.editor.selectscroller.active = not self.editor.selectscroller.active
            self.editor.select:SetProjects(project_list())
        end,
        tooltip = "open/close project menu",
    }

    local play = Button { 
        image = self.icons.play,
        action = function()
            self.editor:playtest()
        end,
        tooltip = "test story",
    }

    local save = Button { 
        image = self.icons.save,
        action = function()
            self.editor:save()
        end,
        tooltip = "save story",
    }

    local export = Button { 
        image = self.icons.export,
        action = function()
            self.editor:export()
        end,
        tooltip = "export standalone story",
    }

    self:add(menu)
    self:add(play)
    self:add(save)
    self:add(export)
end

return MenuBar

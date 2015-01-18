local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"

local PixelTab = require "interface.toolbox.pixel"

local Grid = require "interface.elements.grid"
local TabBar = require "interface.elements.tabbar"

local Toolbox = Class {
    __includes = Panel,
    name = "kooltool toolbox",
    actions = { "press" },
    event = function() end,
}

function Toolbox:init(params)
    self.editor = params.editor
    self.tool = self.editor.active

    params.shape = shapes.Rectangle { x =   0, y =   0,
                                      w = 256, h = 256+9,
                                      anchor = { 0.5, 0.5 } }

    params.colours = {
        line = {255, 255, 255, 255},
        fill = {  0,   0,   0, 255},
    }

    Panel.init(self, params)

    self.icons = {
        pencil = Button.Icon(love.graphics.newImage("images/pencil.png")),
        tiling = Button.Icon(love.graphics.newImage("images/tiles.png")),
        walls  = Button.Icon(love.graphics.newImage("images/walls.png")),
        marker = Button.Icon(love.graphics.newImage("images/marker.png")),
        entity = Button.Icon(love.graphics.newImage("images/entity.png")),
    }

    self.panels = {}

    local padding = 8

    self.panels.tiles = Grid {
        name = "kooltool tile picker",
        x = -128, y = -128 + 48 - 4.5,
        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
        padding = { default=padding },
        spacing = 8,
    }

    self.panels.pixel = PixelTab {
        x = -128, y = -128 + 48 - 4.5,
        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
        editor = params.editor,
    }

    self:add(self.panels.pixel)
    self:add(self.panels.tiles)

    self.toolbar = TabBar {
        x = -128, y = -128 - 4.5,

        shape = shapes.Rectangle { w = self.shape.w, h = 48 },

        colours = params.colours,

        padding = { default = 8 },
        spacing = 16,

        tabs = {
            { name = "pixel", icon = self.icons.pencil, panel = self.panels.pixel },
            { name = "tiles", icon = self.icons.tiling, panel = self.panels.tiles },
            { name = "walls", icon = self.icons.walls,  panel = {} },
            { name = "mark",  icon = self.icons.marker, panel = {} },
        },
    }

    self.toolbar:select("pixel")

    self:add(self.toolbar)
end

function Toolbox:set_tiles(tiles)
    self.panels.tiles:clear()

    for i, button in ipairs(tiles) do
        local button = Button { image = button[1], action = button[2], }

        self.panels.tiles:add(button)

        local tile = self.editor.tools.tile.tile

        button.draw = function(self)
            Button.draw(self)

            if tile == i then
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(colour.cursor(0))
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", -1.5, -1.5, 34, 34)
                love.graphics.setLineWidth(2)
            end
        end
    end
end

function Toolbox:draw()
    self.colours.line = {colour.cursor(0)}
    Panel.draw(self)
end

return Toolbox

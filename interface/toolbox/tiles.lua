local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Grid = require "interface.elements.grid"
local Button = require "interface.elements.button"

local ScrollPanel = require "interface.elements.scroll"

local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"
local tileset = require "generators.tileset"

local TilesPanel = Class {
    __includes = Panel,
    name = "kooltool tiles panel",

    icons = {
        create = Button.Icon(love.graphics.newImage("images/create.png")),
    },

    colours = Panel.COLOURS.black,
}

function TilesPanel:init(params)
    Panel.init(self, params)

    self.editor = params.editor

    self.options = Grid {
        name = "kooltool tile options",

        shape = shapes.Rectangle { w = self.shape.w, h = 48 },
        padding = { default = 8 },
        spacing = 8,
    }

    local function create() self:create_tile() end
    local button = Button { image = self.icons.create, action = create, tooltip = "add new tile", }

    self.options:add(button)

    self.tiles = Grid {
        name = "kooltool tile picker",

        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h },
        padding = { default = 8 },
        spacing = 8,

        colours = Panel.COLOURS.black,

        grow = true,
        tooltip = "choose tile",
    }

    self.scroll = ScrollPanel {
        x = 0, y = 48,
        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
        content = self.tiles,
    }

    self:add(self.options)
    self:add(self.scroll)
end

function TilesPanel:create_tile()
    local tile = self.tileset:add_tile()
    
    tileset.blank(function(brush, ...)
                      self.tileset:applyBrush(tile, brush, ...)
                  end,
                  self.tileset.dimensions,
                  self.editor.project.palette)
end

function TilesPanel:set_tileset(tileset)
    if tileset ~= self.tileset then
        self.tileset = tileset
        self.tileset.changed:add(function() self:refresh() end)

        self:refresh()
    end
end

function TilesPanel:refresh()
    self.tiles:clear()

    for i, quad in ipairs(self.tileset.quads) do
        local function action()
            self.editor.active = self.editor.tools.tile
            self.editor.tools.tile.tile = i
        end
        
        local button = Button { 
            image  = Button.Icon(self.tileset.canvas, quad),
            action = action,
            tooltip = "choose tile",
        }

        button.draw = function()
            local tile = self.editor.tools.tile.tile
            button.highlight = tile == i

            Panel.draw(button)
        end

        self.tiles:add(button)
    end
end

return TilesPanel

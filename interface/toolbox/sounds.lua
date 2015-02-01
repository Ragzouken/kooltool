local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Grid = require "interface.elements.grid"
local Button = require "interface.elements.button"

local ScrollPanel = require "interface.elements.scroll"

local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"
local tileset = require "generators.tileset"

local SoundsPanel = Class {
    __includes = Panel,
    name = "kooltool sounds panel",

    icons = {
        create = Button.Icon(love.graphics.newImage("images/icons/create.png")),
    },

    colours = Panel.COLOURS.black,
}

function SoundsPanel:init(params)
    Panel.init(self, params)

    self.editor = params.editor

    self.options = Grid {
        name = "kooltool sound options",

        shape = shapes.Rectangle { w = self.shape.w, h = 48 },
        padding = { default = 8 },
        spacing = 8,
    }

    local function create() self:create_tile() end
    local button = Button { image = self.icons.create, action = create, tooltip = "add new tile", }

    --self.options:add(button)

    self.sounds = Grid {
        name = "kooltool sound gallery",

        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h },
        padding = { default = 8 },
        spacing = 8,

        colours = Panel.COLOURS.black,

        grow = true,
        tooltip = "choose sound",
    }

    self.scroll = ScrollPanel {
        x = 0, y = 48,
        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
        content = self.sounds,
    }

    self:add(self.options)
    self:add(self.scroll)

    local sounds = love.filesystem.getDirectoryItems("sounds")

    for i, file in ipairs(sounds) do
        if love.filesystem.isFile("sounds/" .. file) then
            local sound = love.audio.newSource("sounds/" .. file)
            local button = Button { image = self.icons.create, action = function() sound:play() end, tooltip = "play sound", }

            self.sounds:add(button)
        end
    end
end

return SoundsPanel

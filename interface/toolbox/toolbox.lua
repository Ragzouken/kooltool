local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"

local PixelTab = require "interface.toolbox.pixel"
local TilesTab = require "interface.toolbox.tiles"
local SpritesTab = require "interface.toolbox.sprites"
local SoundsTab = require "interface.toolbox.sounds"

local Grid = require "interface.elements.grid"
local TabBar = require "interface.elements.tabbar"
local ScrollPanel = require "interface.elements.scroll"

local Toolbox = Class {
    __includes = Panel,
    name = "kooltool toolbox",
    actions = { "press" },
    event = function() end,

    highlight = true,
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
        drag   = Button.Icon(love.graphics.newImage("images/icons/drag.png")),
        pencil = Button.Icon(love.graphics.newImage("images/icons/pencil.png")),
        tiling = Button.Icon(love.graphics.newImage("images/icons/tiles.png")),
        walls  = Button.Icon(love.graphics.newImage("images/icons/walls.png")),
        marker = Button.Icon(love.graphics.newImage("images/icons/marker.png")),
        entity = Button.Icon(love.graphics.newImage("images/icons/entity.png")),
        sound  = Button.Icon(love.graphics.newImage("images/icons/sound.png")),
        music  = Button.Icon(love.graphics.newImage("images/icons/music.png")),
    }

    self.panels = {}

    local function tab()
        return {
            x = -128, y = -128 + 48 - 4.5,
            shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
            editor = params.editor,

            colours = Panel.COLOURS.black,
        }
    end

    self.panels.pixel   = PixelTab(tab())
    self.panels.tiles   = TilesTab(tab())
    self.panels.sprites = SpritesTab(tab())
    self.panels.sounds  = SoundsTab(tab())

    self:add(self.panels.pixel)
    self:add(self.panels.tiles)
    self:add(self.panels.sprites)
    self:add(self.panels.sounds)

    self.toolbar = TabBar {
        name = "kooltool toolbox toolbar",
        x = -128, y = -128 - 4.5,

        shape = shapes.Rectangle { w = self.shape.w, h = 48 },

        colours = params.colours,

        padding = { default = 8 },
        spacing = 8,

        tabs = {
            --{ name = "drag",    icon = self.icons.drag,   panel = {}, tooltip = "move objects" },
            { name = "pixel",   icon = self.icons.pencil, panel = self.panels.pixel,   tooltip = "draw" },
            { name = "tiles",   icon = self.icons.tiling, panel = self.panels.tiles,   tooltip = "lay tiles" },
            { name = "sprites", icon = self.icons.entity, panel = self.panels.sprites, tooltip = "sprites" },
            { name = "walls",   icon = self.icons.walls,  panel = {}, tooltip = "set walls", },
            { name = "mark",    icon = self.icons.marker, panel = {}, tooltip = "make annotations", },
            { name = "sound", icon = self.icons.sound,  panel = self.panels.sounds, tooltip = "sound unavailable at this time", },
            --{ name = "music", icon = self.icons.music,  panel = {}, tooltip = "music unavailable at this time", },
        },

        tooltip = "select a tool",
    }

    self.toolbar:select("pixel")

    self:add(self.toolbar)
end

return Toolbox

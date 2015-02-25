local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"

local PixelTab = require "interface.toolbox.pixel"
local TilesTab = require "interface.toolbox.tiles"
local SpritesTab = require "interface.toolbox.sprites"
local PlanTab = require "interface.toolbox.plan"
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
    block = true,
}

function Toolbox:init(params)
    self.editor = params.editor
    self.tool = self.editor.active

    params.shape = shapes.Rectangle { x =   0, y =   0,
                                      w = 350, h = 350+9,
                                      anchor = { 0.5, 0.5 } }

    params.colours = {
        line = {255, 255, 255, 255},     
        fill = {  0,   0,   0, 255},
    }

    Panel.init(self, params)

    self.icons = {
        drag   = Button.Icon(love.graphics.newImage("images/icons/drag.png")),
        pencil = Button.Icon(love.graphics.newImage("images/icons/drawing.png")),
        tiling = Button.Icon(love.graphics.newImage("images/icons/tiles.png")),
        plan   = Button.Icon(love.graphics.newImage("images/icons/plan.png")),
        walls  = Button.Icon(love.graphics.newImage("images/icons/walls.png")),
        entity = Button.Icon(love.graphics.newImage("images/icons/entity.png")),
        sound  = Button.Icon(love.graphics.newImage("images/icons/sound.png")),
        music  = Button.Icon(love.graphics.newImage("images/icons/music.png")),
    }

    self.panels = {}

    local tlx, tly = -params.shape.w / 2, -params.shape.h / 2

    local function tab()
        return {
            x = tlx, y = tly + 48,
            shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
            editor = params.editor,

            colours = Panel.COLOURS.black,
        }
    end

    self.panels.pixel   = PixelTab(tab())
    self.panels.tiles   = TilesTab(tab())
    self.panels.sprites = SpritesTab(tab())
    self.panels.plan    = PlanTab(tab())
    self.panels.sounds  = SoundsTab(tab())

    self:add(self.panels.pixel)
    self:add(self.panels.tiles)
    self:add(self.panels.sprites)
    self:add(self.panels.plan)
    self:add(self.panels.sounds)

    self.toolbar = TabBar {
        name = "kooltool toolbox toolbar",
        x = tlx, y = tly,

        shape = shapes.Rectangle { w = self.shape.w, h = 48 },

        colours = params.colours,

        padding = { default = 8 },
        spacing = 8,

        tabs = {
            --{ name = "drag",    icon = self.icons.drag,   panel = {}, tooltip = "move objects" },
            { name = "pixel",   icon = self.icons.pencil, panel = self.panels.pixel,   tooltip = "draw" },
            { name = "tiles",   icon = self.icons.tiling, panel = self.panels.tiles,   tooltip = "lay tiles" },
            { name = "sprites", icon = self.icons.entity, panel = self.panels.sprites, tooltip = "sprites" },
            { name = "mark",    icon = self.icons.plan,   panel = self.panels.plan,    tooltip = "make plans", },
            { name = "walls",   icon = self.icons.walls,  panel = {}, tooltip = "set walls", },
            { name = "sound", icon = self.icons.sound,  panel = self.panels.sounds, tooltip = "sound unavailable at this time", },
            --{ name = "music", icon = self.icons.music,  panel = {}, tooltip = "music unavailable at this time", },
        },

        tooltip = "select a tool",
    }

    self.toolbar:select("pixel")

    self:add(self.toolbar)
end

return Toolbox

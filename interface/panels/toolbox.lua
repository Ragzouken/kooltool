local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"

local Toolbox = Class {
    __includes = Panel,
    name = "kooltool toolbox",
    actions = { "press" },
    event = function() end,
}

function Toolbox:init(params)
    self.editor = params.editor

    params.shape = shapes.Rectangle { x =   0, y =   0,
                                      w = 256, h = 256,
                                      anchor = { 0.5, 0.5 } }

    params.colours = {
        stroke = {255, 255, 255, 255},
        fill   = {  0,   0,   0, 255},
    }

    Panel.init(self, params)

    self.icons = {
        pencil = Button.Icon(love.graphics.newImage("images/pencil.png")),
        tiling = Button.Icon(love.graphics.newImage("images/walls.png")),
        entity = Button.Icon(love.graphics.newImage("images/entity.png")),
    }

    self.toolbar = Panel { x = -128, y = -128 }

    self.tabs = {
        draw = Button { x = 8, y = 8,
                        icon = self.icons.pencil,
                        action = function() self.editor.active = self.editor.tools.draw end },
        tile = Button { x = 8 + 32 + 16, y = 8,
                        icon = self.icons.tiling,
                        action = function() self.editor.active = self.editor.tools.tile end },
    }

    self.toolbar:add(self.tabs.draw)
    self.toolbar:add(self.tabs.tile)

    self:add(self.toolbar)
end

function Toolbox:set_tiles(tiles)
    if self.tiles then self:remove(self.tiles) end

    self.tiles = Panel {
        x = -128, y = -128 + 48,
    }

    self.tiles.buttons = {}

    local cols = 6
    local padding = 8
    local spacing = 9

    for i, button in ipairs(tiles) do
        local gx = (i - 1) % cols
        local gy = math.floor((i - 1) / cols)

        local x = padding + gx * 32 + spacing * gx
        local y = padding + gy * 32 + spacing * gy      
        local button = Button { x = x, y = y,
                                icon = button[1], action = button[2], }

        self.tiles:add(button)
        self.tiles.buttons[i] = button

        local tile = self.tool.tile
        local draw = button.draw

        button.draw = function(self)
            draw(self)

            if tile == i then
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(colour.cursor(0))
                love.graphics.rectangle("fill", 0, 0, 32, 32)
            end
        end
    end

    self:add(self.tiles)
end

function Toolbox:draw()
    self.colours.stroke = {colour.cursor(0)}
    Panel.draw(self)
end

return Toolbox

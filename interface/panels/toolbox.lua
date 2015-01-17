local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Button = require "interface.elements.button"
local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local palette = require "generators.palette"

local Grid = require "interface.elements.grid"

local Palette = Class {
    __includes = Panel,
    name = "kooltool palette",
}

function Palette:init(params)
    Panel.init(self, params)

    local eraser = Button.Icon(love.graphics.newImage("images/eraser.png"))
    local reset  = Button.Icon(love.graphics.newImage("images/reset.png"))

    local cols = 6
    local rows = 4
    local padding = 9
    local spacing = 9

    self.layout = Grid { 
        shape = shapes.Rectangle { w = 256, h = 256 },
        padding = { left=padding, right=padding, top=padding, bottom=padding },
        spacing = 9,
    }

    self.palette = palette.generate(cols * rows - 1).colours

    for i=0,cols-1 do
        local button = Panel {
            shape = shapes.Rectangle { w = 32, h = 32 },
            colours = { stroke = {255, 255, 255, 0}, fill = {0, 0, 0, 0}, },
            actions = {"press"},
        }

        button.event = function() params.editor.tools.draw.size = i+1 end

        local draw = button.draw
        button.draw = function(self)
            draw(self)

            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.rectangle("fill", 16.5-i/2, 16-i/2, 1+i, 1+i)

            if params.editor.tools and params.editor.tools.draw.size == i+1 then
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(colour.cursor(0))
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", -1.5, -1.5, 34.5, 34.5)
                love.graphics.setLineWidth(2)
            end
        end

        self:add(button)
        self.layout:add(button)
    end

    for i, colour_ in ipairs(self.palette) do 
        if i == 1 then colour_ = nil end

        local button

        if i == 1 then
            button = Button { icon = eraser }
        else
            button = Panel {
                shape = shapes.Rectangle { w = 32, h = 32},
                colours = { stroke = {0, 0, 0, 0}, fill = colour_, },
                actions = {"press"},
            }
        end

        local draw = button.draw
        button.draw = function(self)
            draw(self)

            if params.editor.tools and params.editor.tools.draw.colour == colour_ then
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(colour.cursor(0))
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", -1.5, -1.5, 34.5, 34.5)
                love.graphics.setLineWidth(2)
            end
        end

        button.event = function() params.editor.tools.draw.colour = colour_ end

        self:add(button)
        self.layout:add(button)
    end

    local reset = Button {
        icon = reset,
        action = function() self:init(params) end,
    }

    self:add(reset)
    self.layout:add(reset)
end

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
        stroke = {255, 255, 255, 255},
        fill   = {  0,   0,   0, 255},
    }

    Panel.init(self, params)

    self.icons = {
        pencil = Button.Icon(love.graphics.newImage("images/pencil.png")),
        tiling = Button.Icon(love.graphics.newImage("images/tiles.png")),
        walls  = Button.Icon(love.graphics.newImage("images/walls.png")),
        marker = Button.Icon(love.graphics.newImage("images/marker.png")),
        entity = Button.Icon(love.graphics.newImage("images/entity.png")),
    }

    self.toolbar = Panel { x = -128, y = -128-4.5 }

    local function tooltab(x, y, icon, tool)
        local button = Button {
            x = x, y = y,
            icon = icon,
            action = function() self.editor.active = tool end,
        }

        button.draw = function(self)
            Button.draw(self)

            if params.editor.active == tool then
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(colour.cursor(0))
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", -1.5-6, -1.5-6, 34.5+12, 34.5+12)
                love.graphics.setLineWidth(2)
            end
        end

        return button
    end

    self.tabs = {
        draw = tooltab(8, 8, self.icons.pencil, self.editor.tools.draw),
        tile = tooltab(8 + 32 + 16, 8, self.icons.tiling, self.editor.tools.tile),
        wall = tooltab(8 + (32 + 16) * 2, 8, self.icons.walls, self.editor.tools.wall),
        marker = tooltab(8 + (32 + 16) * 3, 8, self.icons.marker, self.editor.tools.marker),
    }

    self.panels = {
        colours = Palette { x = -128, y = -128 + 48, editor = params.editor },
        tiles = Panel { x = -128, y = -128 + 48, },
    }

    local padding = 8

    self.panels.tiles.layout = Grid { 
        shape = shapes.Rectangle { w = 256, h = 256 },
        padding = { left=padding, right=padding, top=padding, bottom=padding },
        spacing = 9,
    }

    self:add(self.panels.colours)
    self:add(self.panels.tiles)

    self.toolbar:add(self.tabs.draw)
    self.toolbar:add(self.tabs.tile)
    self.toolbar:add(self.tabs.wall)
    self.toolbar:add(self.tabs.marker)

    self:add(self.toolbar)
end

function Toolbox:update(dt)
    Panel.update(self, dt)

    if self.editor.tools then
        self.panels.colours.active = self.editor.active == self.editor.tools.draw
        self.panels.tiles.active = self.editor.active == self.editor.tools.tile
    end
end

function Toolbox:set_tiles(tiles)
    self.panels.tiles:clear()
    self.panels.tiles.layout:clear()

    for i, button in ipairs(tiles) do
        local button = Button { icon = button[1], action = button[2], }

        self.panels.tiles:add(button)
        self.panels.tiles.layout:add(button)

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
    self.colours.stroke = {colour.cursor(0)}
    Panel.draw(self)
end

return Toolbox

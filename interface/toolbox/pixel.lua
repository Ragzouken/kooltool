local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Grid = require "interface.elements.grid"
local Button = require "interface.elements.button"

local shapes = require "interface.elements.shapes"
local colour_ = require "utilities.colour"
local palette = require "generators.palette"

local PixelPanel = Class {
    __includes = Panel,
    name = "kooltool pixel panel",

    icons = {
        eraser = love.graphics.newImage("images/eraser.png"),
        reset  = love.graphics.newImage("images/reset.png"),
    },

    colours = { line = {255, 255, 255, 0}, fill = {0, 0, 0, 0} },
}

local function highlight_shiv(draw, predicate)
    return function(self)
        draw(self)

        self.highlight = predicate()
    end
end

local function SizeButton(editor, shape, size)
    local button = Panel {
        shape = shape,
        colours = { line = {255, 255, 255, 0}, fill = {0, 0, 0, 0} },
        actions = {"press"},
        tooltip = "change brush size",
    }

    button.event = function() editor.tools.draw.size = size end

    local w, h = shape.w, shape.h
    local x, y = w / 2, h / 2

    button.draw = function(self)
        Panel.draw(self)

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", x + 0.5 - size/2, y - size/2, size, size)

        self.highlight = editor.tools and editor.tools.draw.size == size
    end

    return button
end

local function ColourButton(editor, shape, colour)
    local button = Panel {
        shape = shape,
        colours = { line = {255, 255, 255, 0}, fill = colour or {0, 0, 0, 0} },
        actions = {"press"},
        tooltip = "choose colour",
    }

    button.event = function() editor.tools.draw.colour = colour end

    if not colour then button.image = Button.Icon(PixelPanel.icons.eraser) end

    button.draw = highlight_shiv(button.draw, function() return editor.tools and editor.tools.draw.colour == colour end)

    return button
end

function PixelPanel:init(params)
    Panel.init(self, params)

    self.layout = Grid { 
        shape   = params.shape,
        padding = { default = 9 },
        spacing = 9,
    }

    -- brush size
    local w, h = 32, 32

    self.brushsize = Grid {
        name = "kooltool brush size",
        x = 0, y = 0,
        shape = shapes.Rectangle { w = params.shape.w, h = params.shape.h },
        colours = { line = {255, 255, 255, 0}, fill = {0, 0, 0, 0} },
        actions = {"press"}, -- TODO: replace with blocking
        padding = { default = 9 },
        spacing = 9,
        tooltip = "change brush size",
    } self.brushsize.event = function() end

    local cols = self.brushsize:fit_cells(w, self.brushsize.shape.w)

    for i=1,cols do
        local shape = shapes.Rectangle { w = w, h = h }
        local button = SizeButton(params.editor, shape, i)

        self.brushsize:add(button)
    end
    
    -- palette
    self.palette = Grid {
        name = "kooltool palette",
        x = 0, y = 50,
        shape = shapes.Rectangle { w = params.shape.w, h = params.shape.h },
        colours = { line = {255, 255, 255, 0}, fill = {0, 0, 0, 0} },
        actions = {"press"}, -- TODO: replace with blocking

        padding = { default = 9, top = 0 },
        spacing = 9,
        tooltip = "choose colour",
    } self.palette.event = function() end

    self:add(self.brushsize)
    self:add(self.palette)

    self:regenerate(params.editor)
end

function PixelPanel:regenerate(editor)
    self.palette:clear()

    local w, h = 32, 32
    local colours = 23
    local palette = palette.generate(colours).colours

    for i, colour in ipairs(palette) do 
        if i == 1 then colour = nil end

        local shape = shapes.Rectangle { w = w, h = h }
        local button = ColourButton(editor, shape, colour)

        self.palette:add(button)
    end

    local reset = Button {
        image  = Button.Icon(self.icons.reset),
        action = function() self:regenerate(editor) end,
        tooltip = "randomise colours",
    }

    self.palette:add(reset)
end

return PixelPanel

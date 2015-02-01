local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Grid = require "interface.elements.grid"
local Button = require "interface.elements.button"

local Notebox = require "components.notebox"

local shapes = require "interface.elements.shapes"

local PlanPanel = Class {
    __includes = Panel,
    name = "kooltool plan panel",

    icons = {
        marker = love.graphics.newImage("images/icons/marker.png"),
        eraser = love.graphics.newImage("images/icons/eraser.png"),
        note   = love.graphics.newImage("images/icons/note.png"),
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

    button.event = function() editor.tools.marker.size = size end

    local w, h = shape.w, shape.h
    local x, y = w / 2, h / 2

    button.draw = function(self)
        Panel.draw(self)

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", x + 0.5 - size/2, y - size/2, size, size)

        self.highlight = editor.tools and editor.tools.marker.size == size
    end

    return button
end

function PlanPanel:init(params)
    Panel.init(self, params)

    self.editor = params.editor

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
    
    self.whatever = Grid {
        name = "kooltool thing",
        x = 0, y = 50,
        shape = shapes.Rectangle { w = params.shape.w, h = params.shape.h },
        colours = { line = {255, 255, 255, 0}, fill = {0, 0, 0, 0} },
        actions = {"press"}, -- TODO: replace with blocking

        padding = { default = 9, top = 0 },
        spacing = 9,
        tooltip = "dunno sorry",
    } self.whatever.event = function() end

    local function action()
    end
    
    local button = Button { 
        image  = Button.Icon(self.icons.note),
        action = action,
        tooltip = "marker",
    }

    function button.event(button, event)
        local sx, sy, wx, wy = unpack(event.coords)
        local target, x, y = self.editor:target("note", sx, sy)

        local notebox = Notebox(target)
        notebox:blank(x, y, "[note]")
        target:add(notebox)

        self.editor.action = self.editor.tools.drag
        self.editor.action:grab(notebox, sx, sy)

        --self.editor.focus = notebox
        self.editor.toolbox.active = false
    end

    self.whatever:add(button)

    self:add(self.brushsize)
    self:add(self.whatever)
end

return PlanPanel

local Class = require "hump.class"
local Panel = require "interface.elements.panel"
local Grid = require "interface.elements.grid"
local Button = require "interface.elements.button"

local ScrollPanel = require "interface.elements.scroll"

local Entity = require "components.entity"

local shapes = require "interface.elements.shapes"
local colour = require "utilities.colour"
local generators = require "generators"

local SpritesPanel = Class {
    __includes = Panel,
    name = "kooltool sprites panel",

    icons = {
        create = Button.Icon(love.graphics.newImage("images/icons/create.png")),
    },

    colours = Panel.COLOURS.black,
}

function SpritesPanel:init(params)
    Panel.init(self, params)

    self.editor = params.editor

    self.options = Grid {
        name = "kooltool sprite options",

        shape = shapes.Rectangle { w = self.shape.w, h = 48 },
        padding = { default = 8 },
        spacing = 8,
    }

    local function create() self:create_sprite() end
    local button = Button { image = self.icons.create, action = create, tooltip = "add new sprite", }

    self.options:add(button)

    self.sprites = Grid {
        name = "kooltool sprite gallery",

        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h },
        padding = { default = 8 },
        spacing = 8,

        colours = Panel.COLOURS.black,

        grow = true,
        tooltip = "choose sprite",
    }

    self.scroll = ScrollPanel {
        x = 0, y = 48,
        shape = shapes.Rectangle { w = self.shape.w, h = self.shape.h - 48 },
        content = self.sprites,
    }

    self:add(self.options)
    self:add(self.scroll)
end

function SpritesPanel:create_sprite()
    local project = self.editor.project
    local sprite = generators.sprite.mess(project.gridsize, project.palette)

    project:add_sprite(sprite)

    self:refresh()
end

function SpritesPanel:refresh()
    self.sprites:clear()

    local quad = love.graphics.newQuad(0, 0, 32, 32, 32, 32)

    for sprite in pairs(self.editor.project.sprites) do
        local function action()
        end
        
        local button = Button { 
            image  = Button.Icon(sprite.canvas, quad),
            action = action,
            tooltip = "choose sprite",
        }

        function button.event(button, event)
            local sx, sy, wx, wy = unpack(event.coords)
            local target, x, y = self.editor:target("entity", sx, sy)

            local entity = Entity()
            target:entity():add(entity)
            entity:blank(x, y, sprite)

            self.editor.action = self.editor.tools.drag
            self.editor.action:grab(entity, sx, sy)
            self.editor.toolbox.active = false
        end

        self.sprites:add(button)
    end
end

return SpritesPanel

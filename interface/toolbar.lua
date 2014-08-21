local Class = require "hump.class"

local Toolbar = Class {
    buttons = {
        {love.graphics.newImage("images/pencil.png"), function(toolbar)
            toolbar.interface.active = toolbar.interface.tools.draw
        end},
        {love.graphics.newImage("images/tiles.png"), function()
            toolbar.interface.active = toolbar.interface.tools.tile
        end},
        {love.graphics.newImage("images/walls.png"), function()
            toolbar.interface.active = toolbar.interface.tools.wall
        end},
        {love.graphics.newImage("images/marker.png"), function()
            toolbar.interface.active = toolbar.interface.tools.marker
        end},
        {love.graphics.newImage("images/entity.png"), function()
        end},
        {love.graphics.newImage("images/note.png"), function()
        end},
        {love.graphics.newImage("images/save.png"), function()
        end},
        {love.graphics.newImage("images/export.png"), function()
        end},
    }
}

function Toolbar:init(interface)
end

return Toolbar

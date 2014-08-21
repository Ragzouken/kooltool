local Class = require "hump.class"
local Pane = require "interface.pane"

local colour = require "colour"

local Toolbar = Class {
    __includes = Pane,

    buttons = {
        {love.graphics.newImage("images/pencil.png"), function(toolbar)
            toolbar.interface.active = toolbar.interface.tools.draw
        end},
        {love.graphics.newImage("images/tiles.png"), function(toolbar)
            toolbar.interface.active = toolbar.interface.tools.tile
        end},
        {love.graphics.newImage("images/walls.png"), function(toolbar)
            toolbar.interface.active = toolbar.interface.tools.wall
        end},
        {love.graphics.newImage("images/marker.png"), function(toolbar)
            toolbar.interface.active = toolbar.interface.tools.marker
        end},
        {love.graphics.newImage("images/entity.png"), function(toolbar, sx, sy, wx, wy)
            local entity = toolbar.interface.project:newEntity(wx, wy)
            toolbar.interface.action = toolbar.interface.tools.drag
            toolbar.interface.action:grab(entity, sx, sy, wx, wy)
        end},
        {love.graphics.newImage("images/note.png"), function(toolbar, sx, sy, wx, wy)
            local notebox = toolbar.interface.project:newNotebox(wx, wy)
            toolbar.interface.action = toolbar.interface.tools.drag
            toolbar.interface.action:grab(notebox, sx, sy, wx, wy)
        end},
        {love.graphics.newImage("images/save.png"), function(toolbar)
            SAVESOUND:play()
            toolbar.interface.project:save("projects/" .. toolbar.interface.project.name)
            love.system.openURL("file://"..love.filesystem.getSaveDirectory())
        end},
        {love.graphics.newImage("images/export.png"), function(toolbar)
            SAVESOUND:play()
            toolbar.interface.project:save("projects/" .. toolbar.interface.project.name)
            toolbar.interface.project:export()
            love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/releases/" .. PROJECT.name)
        end},
    }
}

function Toolbar:draw()
    local margin = 4

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode("premultiplied")
    love.graphics.rectangle("fill", margin-1, margin-1, 32+3, #self.buttons*(32+1)+1)

    --love.graphics.setColor(self.interface.tools.draw.colour)
    love.graphics.setColor(0, 0, 0, 255)

    for i, button in ipairs(self.buttons) do
        local graphic, action = unpack(button)

        love.graphics.draw(graphic, margin, margin + (i-1) * 33 + 1, 0, 1, 1)
    end

    local tools = {
        self.interface.tools.draw,
        self.interface.tools.tile,
        self.interface.tools.wall,
        self.interface.tools.marker,
    }

    love.graphics.setBlendMode("alpha")
    for i, tool in ipairs(tools) do
        if tool == self.interface.active then
            local x, y = margin, margin + (i - 1) * (32 + 1)
            love.graphics.setColor(colour.cursor(0))
            love.graphics.rectangle("line", x+0.5, y+0.5, 32, 32)
        end
    end
end

function Toolbar:mousepressed(button, sx, sy, wx, wy)
    local margin = 4

    if sx > margin and sy > margin and sx < margin + 32 + 2 then
        local i = math.floor((sy - margin) / 33) + 1

        if i <= #self.buttons then
            self.buttons[i][2](self, sx, sy, wx, wy)
            return true
        end
    end
end

return Toolbar

local Class = require "hump.class"
local EditMode = require "editmode"

local colour = require "colour"

local ProjectSelectMode = Class { __includes = EditMode, name = "select project", }

local Interface = Class {
    images = {
        new_project = love.graphics.newImage("images/new_project.png"),
    },

    fonts = {
        large = love.graphics.newFont("fonts/PressStart2P.ttf", 32),
        medium = love.graphics.newFont("fonts/PressStart2P.ttf", 16),
        small = love.graphics.newFont("fonts/PressStart2P.ttf", 8),
    },
}

function Interface:init(projects)
    self.x, self.y = 32, 32
    self.projects = projects

    self.modes = {
        select_project = ProjectSelectMode(self),
    }
end

function Interface:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)

    local text = "this is a description but just for testing purposes soon you'll be able to edit this and the project icon but not yet"

    for i, project in ipairs(self.projects) do
        local lx, ly = self.x, self.y + (i - 1) * 64

        love.graphics.setColor(PALETTE.colours[1])
        love.graphics.rectangle("fill", lx + 64, ly, 512 - 64 - 64, 32-4)
        love.graphics.setColor(PALETTE.colours[2])
        love.graphics.rectangle("fill", lx + 64, ly + 32-4, 512 - 64 - 64, 32+4)

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(project.icon, lx, ly, 0, 2, 2)
        
        local font = self.fonts.medium
        local height = font:getHeight()
        local oy = font:getAscent() - font:getBaseline()
        love.graphics.setFont(font)

        love.graphics.print(project.name, lx + 64 + 8, ly + oy + 8)
        
        local font = self.fonts.small
        local height = font:getHeight()
        local oy = font:getAscent() - font:getBaseline()
        love.graphics.setFont(font)
            
        love.graphics.printf(text, lx + 64 + 8, ly + oy + 8 + 24, 512 - 64 - 64)
    end

    local font = self.fonts.medium
    local height = font:getHeight()
    local oy = font:getAscent() - font:getBaseline()
    love.graphics.setFont(font)

    local lx, ly = self.x, self.y + #self.projects * 64
    love.graphics.draw(self.images.new_project, lx, ly, 0, 2, 2)
    love.graphics.print("start new project", lx + 64 + 8, ly + oy + 8)

    local font = self.fonts.small
    local height = font:getHeight()
    local oy = font:getAscent() - font:getBaseline()
    love.graphics.setFont(font)
        
    local text = [[
create a new project, for now it is named for you randomly]]

    love.graphics.printf(text, lx + 64 + 8, ly + oy + 8 + 24, 512 - 64 - 64)
end

function ProjectSelectMode:draw()
    local mx, my = love.mouse.getPosition()
    local i = math.floor((my - 32) / 64) + 1
    local lx, ly = self.layer.x, self.layer.y + (i - 1) * 64

    if i >= 1 and i <= #self.layer.projects + 1 then
        love.graphics.setColor(colour.random(128, 255))
        love.graphics.rectangle("line", lx, ly, 512 - 64, 64)
    end
end

function ProjectSelectMode:mousepressed(x, y, button)
    local mx, my = love.mouse.getPosition()
    local i = math.floor((my - 32) / 64) + 1

    if button == "l" then
        SETPROJECT(self.layer.projects[i])
    end
end

return Interface

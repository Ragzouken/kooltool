local Class = require "hump.class"
local Tileset = require "tileset"
local TileLayer = require "tilelayer"
local NoteLayer = require "notelayer"
local Notebox = require "notebox"
local json = require "json"

local Project = Class {}

function Project.default()
    local project = Project()

    project.tileset = Tileset()
    project.tilelayer = TileLayer(project.tileset)
    project.notelayer = NoteLayer()

    project.tileset:renderTo(project.tileset:add_tile(), function()
        love.graphics.setColor(PALETTE.colours[1])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end)

    project.tileset:renderTo(project.tileset:add_tile(), function()
        love.graphics.setColor(PALETTE.colours[2])
        love.graphics.rectangle("fill", 0, 0, 32, 32)
    end)

    for y=0,7 do
        for x=0,7 do
            project.tilelayer:set(love.math.random(2), x, y)
        end
    end

    local defaultnotes = {
[[
welcome to kooltool
please have fun]],
[[
in pixel mode (q) draw you can 
create a set of beautiful tiles
as building blocks for a world]],
[[
in tile mode (w) you can build your
own landscape from your tiles]],
[[
in note mode (e) you can keep notes
and make annotations on your project
for planning and commentary
     (escape to leave mode)]],
[[
press alt to copy the tile or
colour currently under the mouse]],
[[
you can drag notes
around in note mode]],
[[
you can delete notes with
right click in note mode]],
[[
hold the middle click and drag
to move around the world]],
[[
use the mouse wheel
to zoom in and out]],
[[
press s to save]],
[[
hold control to erase annotations]],
    }

    for i, note in ipairs(defaultnotes) do
        local x = love.math.random(256-128, 512-128)
        local y = (i - 1) * (512 / #defaultnotes) + 32
        project.notelayer:addNotebox(Notebox(project.notelayer, x, y, note))
    end

    return project
end

function Project:init()
end

function Project:load(folder_path)
    self.tileset = Tileset()

    local tiles = love.graphics.newImage(folder_path .. "/tileset.png")
    self.tileset.canvas:renderTo(function()
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(tiles, 0, 0)
    end)

    local data = love.filesystem.read(folder_path .. "/tilelayer.json")
    self.tilelayer = TileLayer(self.tileset)
    self.tilelayer:deserialise(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/notelayer.json")
    self.notelayer = NoteLayer()
    self.notelayer:deserialise(json.decode(data), folder_path)
end

function Project:save(folder_path)
    love.filesystem.createDirectory(folder_path)
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.tilelayer:serialise()))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.notelayer:serialise(folder_path)))
    file:close()

    local data = self.tileset.canvas:getImageData()
    data:encode(folder_path .. "/tileset.png")
end

function Project:update(dt)
    self.notelayer:update(dt)
end

function Project:draw()
    self.tilelayer:draw()
    self.notelayer:draw()
end

return Project

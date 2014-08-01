local Class = require "hump.class"
local TileLayer = require "tilelayer"
local NoteLayer = require "notelayer"
local json = require "json"

local Project = Class {}

function Project.default()
    local project = Project()

    project.tilelayer = TileLayer.default()
    project.notelayer = NoteLayer.default()
    project.tileset = project.tilelayer.tileset

    return project
end

function Project:init()
end

function Project:load(folder_path)
    local data = love.filesystem.read(folder_path .. "/tilelayer.json")
    self.tilelayer = TileLayer(self.tileset)
    self.tilelayer:deserialise(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/notelayer.json")
    self.notelayer = NoteLayer()
    self.notelayer:deserialise(json.decode(data), folder_path)

    self.tileset = self.tilelayer.tileset
end

function Project:save(folder_path)
    love.filesystem.createDirectory(folder_path)
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.tilelayer:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.notelayer:serialise(folder_path)))
    file:close()
end

function Project:update(dt)
    self.tilelayer:update(dt)
    self.notelayer:update(dt)
end

function Project:draw()
    self.tilelayer:draw()
    self.notelayer:draw()
end

return Project

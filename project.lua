local Class = require "hump.class"
local TileLayer = require "tilelayer"
local NoteLayer = require "notelayer"
local EntityLayer = require "entitylayer"
local StringGenerator = require "stringgenerator"

local common = require "common"
local json = require "json"

local Project = Class {}

do
    local names = {}

    for line in love.filesystem.lines("texts/names.txt") do
        names[#names+1] = line
    end

    Project.name_generator = StringGenerator(names)
end

function Project.default(name)
    local project = Project(name)

    project.tilelayer = TileLayer.default()
    project.notelayer = NoteLayer()
    project.entitylayer = EntityLayer()

    return project
end

function Project:init(name)
    self.name = name
end

function Project:load(folder_path)
    local data = love.filesystem.read(folder_path .. "/tilelayer.json")
    self.tilelayer = TileLayer(self.tileset)
    self.tilelayer:deserialise(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/notelayer.json")
    self.notelayer = NoteLayer()
    self.notelayer:deserialise(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/entitylayer.json")
    self.entitylayer = EntityLayer()
    self.entitylayer:deserialise(json.decode(data), folder_path)
end

function Project:save(folder_path)
    love.filesystem.createDirectory(folder_path)
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.tilelayer:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.notelayer:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/entitylayer.json", "w")
    file:write(json.encode(self.entitylayer:serialise(folder_path)))
    file:close()

    self.tilelayer:exportRegions(folder_path)
end

function Project:loadIcon(folder_path)
    local file = folder_path .. "/icon.png"

    if not pcall(function() self.icon = common.loadCanvas(file) end) then
        self.icon = love.graphics.newCanvas(32, 32)
    end
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

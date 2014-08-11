local Class = require "hump.class"
local Collider = require "collider"
local SurfaceLayer = require "layers.surface"
local TileLayer = require "tilelayer"
local NoteLayer = require "notelayer"
local EntityLayer = require "entitylayer"

local generators = require "generators"
local common = require "common"
local json = require "json"
local export = require "export"

local Project = Class {}

do
    local names = {}

    for line in love.filesystem.lines("texts/names.txt") do
        names[#names+1] = line
    end

    Project.name_generator = generators.String(names)
end

function Project.default(name)
    local project = Project(name)

    project.palette = PALETTE
    project.layers.surface = generators.surface.default(project)

    project.tilelayer = TileLayer.default(project)
    project.notelayer = NoteLayer()
    project.entitylayer = EntityLayer()

    return project
end

function Project:init(name)
    self.name = name:match("[^/]+$")

    self.dragables = Collider(128)

    self.layers = {}
end

function Project:load(folder_path)
    if self.name == "tutorial" then self.name = "tutorial_copy" end

    self.layers.surface = SurfaceLayer(self)

    local data = love.filesystem.read(folder_path .. "/tilelayer.json")
    self.tilelayer = TileLayer(self)
    self.layers.surface:deserialise(json.decode(data), folder_path)

    local data = love.filesystem.read(folder_path .. "/notelayer.json")
    self.notelayer = NoteLayer()
    self.notelayer:deserialise(json.decode(data), folder_path)

    self.entitylayer = EntityLayer()
    
    local entitylayer_path = folder_path .. "/entitylayer.json"

    if love.filesystem.exists(entitylayer_path) then
        local data = love.filesystem.read(entitylayer_path)
        self.entitylayer:deserialise(json.decode(data), folder_path)
    end
end

function Project:save(folder_path)
    love.filesystem.createDirectory(folder_path)
    local file = love.filesystem.newFile(folder_path .. "/tilelayer.json", "w")
    file:write(json.encode(self.layers.surface:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/notelayer.json", "w")
    file:write(json.encode(self.notelayer:serialise(folder_path)))
    file:close()

    local file = love.filesystem.newFile(folder_path .. "/entitylayer.json", "w")
    file:write(json.encode(self.entitylayer:serialise(folder_path)))
    file:close()

    self.layers.surface:exportRegions(folder_path)
end

function Project:loadIcon(folder_path)
    local file = folder_path .. "/icon.png"

    if not pcall(function() self.icon = common.loadCanvas(file) end) then
        self.icon = love.graphics.newCanvas(32, 32)
    end
end

function Project:update(dt)
    self.layers.surface:update(dt)
    self.notelayer:update(dt)
end

function Project:draw()
    self.tilelayer:draw()
    self.entitylayer:draw()
    --self.notelayer:draw()
end

function Project:sample()
end

Project.export = export.export

return Project

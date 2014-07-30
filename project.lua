local Class = require "hump.class"

local Project = Class {}

function Project.load(name)
end

function Project:init(name)
    self.name = name
end

function Project:save()
end

return Project

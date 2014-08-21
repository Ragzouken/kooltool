local Class = require "hump.class"
local Tool = require "tools.tool"

local Type = Class {
    __includes = Tool,
    name = "annotate",
    typing_sound = love.audio.newSource("sounds/typing.wav"),
}

function Type:init(project)
    Tool.init(self)
    
    self.project = project
end

function Type:cursor()
    
end

function Type:keypressed(key, sx, sy, wx, wy)
    if self.target then
        return self.target:keypressed(key)
    end
end

function Type:textinput(character)
    if self.target then
        return self.target:textinput(character)
    end
end

return Type

local Class = require "hump.class"
local ScriptNode = require "components.scripting.scriptnode"

local DialogueNode = Class {
    __includes = ScriptNode,

    icon = love.graphics.newImage("images/scriptnodes/dialogue.png"),
}

function DialogueNode:serialise(saves)
end

function DialogueNode:init(...)
    ScriptNode.init(self, ...)

    self.message = "test message"
end

return DialogueNode

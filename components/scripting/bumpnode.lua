local Class = require "hump.class"
local ScriptNode = require "components.scripting.scriptnode"

local BumpNode = Class {
    __includes = ScriptNode,

    icon = love.graphics.newImage("images/scriptnodes/bump.png"),
}

return BumpNode

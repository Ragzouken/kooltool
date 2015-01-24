local Class = require "hump.class"
local Panel = require "interface.elements.panel"

local Popouts = Class {
    __includes = Panel,
    name = "kooltool popout tracker",
    actions = {"dismiss"},
}

function Popouts:register(params)
    
    -- TODO: reposition popout so it doesn't move during reparenting
    params.destination:add(params.popout)
end

return Popouts

local Class = require "hump.class"
local elements = require "interface.elements"

local NewProjectPanel = Class {
    __includes = elements.Panel,
    name = "kooltool new project panel",
}

function NewProjectPanel:init(params)
    elements.Panel.init(self, params)

    self.
end

return NewProjectPanel

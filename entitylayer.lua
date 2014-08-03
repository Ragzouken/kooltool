local Class = require "hump.class"
local EditMode = require "editmode"

local PixelMode = Class { __includes = EditMode, name = "edit entities" }
local PlaceMode = Class { __includes = EditMode, name = "place entities" }

local EntityLayer = Class {}

function EntityLayer.default()
    local layer = EntityLayer()

    return layer
end

function EntityLayer:deserialise(data, saves)
end

function EntityLayer:serialise(saves)
    return {}
end

function EntityLayer:init()
    self.active = true

    self.modes = {
        pixel = PixelMode(self),
        place = PlaceMode(self),
    }
end

return EntityLayer

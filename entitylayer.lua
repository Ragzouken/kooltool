local Class = require "hump.class"
local EditMode = require "editmode"

local PixelMode = Class { __includes = EditMode, name = "edit entities" }

local EntityLayer = Class {}

return EntityLayer

local Class = require "hump.class"

local Resource = Class {
    type = "Resource",
}

function Resource:init()
end

function Resource:serialise()
end

function Resource:deserialise()
end

function Resource:finalise()
end

return Resource

local Class = require "hump.class"

local Event = Class {}

function Event:init()
    self.listeners = {}
end

function Event:add(listener)
    self.listeners[listener] = true
end

function Event:remove(listener)
    self.listeners[listener] = false
end

function Event:fire(...)
    for listener in pairs(self.listeners) do
        listener(...)
    end
end

return Event

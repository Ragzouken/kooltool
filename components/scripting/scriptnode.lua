local Class = require "hump.class"

local shapes = require "collider.shapes"

local ScriptNode = Class {
    radius = 16,
    icon = love.graphics.newImage("images/scriptnodes/script.png"),
}

function ScriptNode:serialise(saves)
    assert(false, "no serialisation implemented")
end

function ScriptNode:deserialise(data, saves)
    assert(false, "no deserialisation implemented")
end

function ScriptNode:init(brain, x, y)
    self.brain = brain
    self.x, self.y = x or 0, y or 0
    self.shape = shapes.newCircleShape(self.x, self.y, self.radius)
end

function ScriptNode:draw()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 0, 255, 255)
    self.shape:draw("fill")

    love.graphics.setBlendMode("premultiplied")
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(self.icon, self.x, self.y, 0, 1, 1, 16, 16)
end

return ScriptNode

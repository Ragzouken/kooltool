local Class = require "hump.class"

local hsv = require "hsv"

local Palette = Class {}

function Palette.generate(colour_count)
    colours = {}

    local offset = love.math.random() * 255

    for i=1,colour_count do
        local hue = (255 / colour_count * (i - 1) + offset) % 255
        local sat = love.math.random() * 128 + 127
        local val = love.math.random() * 128 + 127

        colours[i] = {hsv(hue, sat, val)}
    end

    return Palette(colours)
end

function Palette:init(colours)
    self.colours = colours
end

return Palette

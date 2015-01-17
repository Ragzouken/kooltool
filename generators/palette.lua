local Class = require "hump.class"

local colour = require "utilities.colour"

local Palette = Class {}

local function normal()
    local count = math.random(2, 7)
    local sum = 1

    for i=2,count do
        sum = sum + love.math.random()
    end

    return sum / count
end

function Palette.generate(colour_count)
    local colours = {}

    local offset = love.math.random() * 255

    for i=1,colour_count do
        local u = i / colour_count
        local hue = (255 / colour_count * (i - 1) + offset) % 255
        local sat, val = normal() * 255, normal() * 255 

        colours[i] = {colour.hsv(hue, sat, val)}
    end

    return Palette(colours)
end

function Palette:init(colours)
    self.colours = colours
end

return Palette

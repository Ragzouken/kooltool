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

local function ramp(count, hue, shift, sat)
    local colours = {}

    for i=0,count-1 do
        local u = i / (count-1)
        
        local h = (hue - shift * (u - 0.5))
        local w = (0.5 - math.abs(0.5 - u)) * sat * 0.1
        local s = (u + w) * 0.8 + 0.2
        local v = (u + w) * 0.7 + 0.15

        colours[i+1] = {colour.hsl(h * 255, s * 255, v * 255)}
    end

    return colours
end

local function sign() return love.math.random() > 0.5 and -1 or 1 end
local function thing() return (love.math.random() + love.math.random()) / 2 end

function Palette.random_ramp(count)
    return ramp(count, thing(), thing() * sign() * 0.75, thing() * sign())
end

function Palette.generate(colour_count, length)
    local colours = {}
    local s = 1

    local shift = love.math.random()
    local ramps = colour_count / length

    while colour_count > 0 do
        local count = math.min(colour_count, length)
        colour_count = colour_count - count
        
        local cols = ramp(count, (shift + s * (1 / ramps)) % 1, thing() * sign() * 0.75, thing() * sign())

        for i, colour in ipairs(cols) do
            table.insert(colours, colour)
        end

        s = s + 1
    end

    return Palette(colours)
end

function Palette:init(colours)
    self.colours = colours
end

return Palette

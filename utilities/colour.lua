-- Converts HSV to RGB. (input and output range: 0 - 255)

local husl = require "utilities.husl"

local function hsv(h, s, v)
    if s <= 0 then return v, v, v end
    h, s, v = h/256*6, s/255, v/255

    local c = v * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = v-c, 0, 0, 0

    if     h < 1 then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end

    return (r+m)*255, (g+m)*255, (b+m)*255
end

local function hsl(h, s, l)
    if s <= 0 then return l, l, l end
    h, s, l = h/256*6, s/255, l/255

    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m, r, g, b = (l-0.5*c), 0, 0, 0
    
    if     h < 1 then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end

    return math.ceil((r+m) * 255),
           math.ceil((g+m) * 255),
           math.ceil((b+m) * 255)
end

local t = 0
local function cursor(dt, alpha, shift)
    t = t + dt * 0.5
    local u = (t + (shift or 0)) % 1
    local r, g, b = husl.huslp_to_rgb(u * 360, 100, 75)

    return r*255, g*255, b*255, alpha or 192
end

local t = 0
local function walls(dt, hue, alpha)
    t = t + dt * 3
    local u = t % 7 / 7
    local v = math.sin(u * math.pi * 2) * 0.5 + 0.5
    local r, g, b = hsv(hue, 255, 128 + 127 * 1)--v)

    return r, g, b, v * 128 + 127
end

local function random(low, high)
    local low, high = low or 0, high or 255
    local r = love.math.random(low, high)
    local g = love.math.random(low, high)
    local b = love.math.random(low, high)

    return r, g, b
end

return {
    hsv = hsv,
    hsl = hsl,
    random = random,
    cursor = cursor,
    walls = walls,
}

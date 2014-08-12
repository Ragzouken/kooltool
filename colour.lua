-- Converts HSV to RGB. (input and output range: 0 - 255)

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

local t = 0
local function cursor(dt)
    t = t + dt * 3
    local u = t % 7 / 7
    local r, g, b = hsv(u * 255, 255, 255)

    return r, g, b, 192
end

local t = 0
local function walls(dt, hue)
    t = t + dt * 3
    local u = t % 7 / 7
    local v = math.sin(u * math.pi * 2) * 0.5 + 0.5
    local r, g, b = hsv(hue, 255, 128 + 127 * v)

    return r, g, b, 128
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
    random = random,
    cursor = cursor,
    walls = walls,
}

local Tileset = require "components.tileset"
local Brush = require "tools.brush"
local Turtle = require "generators.common"
local Palette = require "generators.palette"

local tileset = {}

local function dark(colours)
    local quart = math.ceil(#colours / 4)
    local index = love.math.random(#colours-quart)

    return colours[index]
end

local function light(colours)
    local quart = math.ceil(#colours / 4)
    local index = love.math.random(quart, #colours)

    return colours[index]
end

function tileset.floor(apply, tilesize, colours)
    local w, h = unpack(tilesize)
    local s = math.max(w, h)

    local brush, x, y = Brush.line(w / 2, h / 2, w / 2, h / 2, s, dark(colours))
    apply(brush, false, x, y)

    local function line(x1, y1, x2, y2, size, colour)
        for xo=-1,1 do
            for yo=-1,1 do
                local brush, x, y = Brush.line((x1 + xo) * w,
                                               (y1 + yo) * h,
                                               (x2 + xo) * w,
                                               (y2 + yo) * h, size, colour)

                apply(brush, false, x, y)
            end
        end
    end

    local function branch(x, y, depth)
        x, y = x % 1, y % 1

        local a1, d1 = love.math.random() * math.pi * 2, love.math.random()
        local a2, d2 = love.math.random() * math.pi * 2, love.math.random()

        local x1, y1 = x + math.cos(a1) * d1, y + math.sin(a1) * d1
        local x2, y2 = x + math.cos(a2) * d2, y + math.sin(a2) * d2

        line(x, y, x1, y1, love.math.random(4), colours[depth+math.random(0,1)])--dark(colours))
        line(x, y, x2, y2, love.math.random(4), colours[depth+math.random(0,1)])--dark(colours))

        if 1 / depth > love.math.random() then branch(x1, y1, depth+1) end
        if 1 / depth > love.math.random() then branch(x2, y2, depth+1) end
    end

    for i=1,2 do
        branch(0.5, 0.5, 1)
    end
end

function tileset.wall(apply, tilesize, colours)
    local w, h = unpack(tilesize)
    local s = math.max(w, h)

    local brush, x, y = Brush.line(w / 2, h / 2, w / 2, h / 2, s, light(colours))
    apply(brush, false, x, y)

    local function line(x1, y1, x2, y2, size, colour)
        x1, y1 = x1 % 1, y1 % 1
        x2, y2 = x2 % 1, y2 % 1

        local brush, x, y = Brush.line(x1*w, y1*h, x2*w, y2*h, size, colour)
        apply(brush, false, x, y)
    end

    local function branch(x, y, depth)
        x, y = x % 1, y % 1

        local a1, d1 = love.math.random() * math.pi * 2, love.math.random() * 0.1
        local a2, d2 = love.math.random() * math.pi * 2, love.math.random() * 0.1

        local x1, y1 = math.cos(a1) * d1, math.sin(a1) * d1
        local x2, y2 = math.cos(a2) * d2, math.sin(a2) * d2

        line(x, y, x+x1, y+y1, 2, light(colours))
        line(x, y, x+x2, y+y2, 2, light(colours))

        if 1 / depth > love.math.random() then branch(x1, y1, depth+1) end
        if 1 / depth > love.math.random() then branch(x2, y2, depth+1) end
    end

    for i=1,2 do
        branch(0.5, 0.5, 1)
    end
end

function tileset.blank(apply, tilesize, palette)
    local w, h = unpack(tilesize)
    local s = math.max(w, h)

    local brush, x, y = Brush.line(w / 2, h / 2, w / 2, h / 2, s, palette.colours[4])
    apply(brush, false, x, y)
end

function tileset.flat(project)
    local generators = require "generators"

    local tileset_ = Tileset(project.gridsize)

    local tile = tileset_:add_tile()
    tileset.floor(function(brush, ...) tileset_:applyBrush(tile, brush, ...) end,
                  project.gridsize,
                  Palette.random_ramp(8))

    local tile = tileset_:add_tile()
    tileset.wall(function(brush, ...) tileset_:applyBrush(tile, brush, ...) end,
                 project.gridsize,
                 Palette.random_ramp(8))

    return tileset_
end

return tileset

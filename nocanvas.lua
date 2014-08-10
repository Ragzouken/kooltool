--function love.load() image = love.graphics.newImage("images/nocanvas.png") end
--function love.update(dt) end
--function love.draw() love.graphics.draw(image, 0, 0) end
--do return end

local broken = love.graphics.newImage("images/broken.png")
local common = require "common"

local Brush = require "brush"
local bresenham = require "bresenham"

NOCANVAS = true

local function FakeCanvas(canvas)
    canvas.fake = true

    function canvas:renderTo(render)
        print("RENDERING TO FAKE CANVAS IS NOT SUPPORTED")
        assert(false)    
    end

    function canvas:getDimensions()
        return self.image:getDimensions()
    end

    function canvas:getData()
        return self.image:getData()
    end

    function canvas:getPixel(...)
        return self.image:getData():getPixel(...)
    end

    function canvas:clear(r, g, b, a)
        self.image:getData():mapPixel(function(x, y)
            return r, g, b, a
        end)
    end

    return canvas
end

function love.graphics.newCanvas(w, h)
    return FakeCanvas{
        image = love.graphics.newImage(love.image.newImageData(w, h)),
    }
end

function common.canvasFromImage(image)
    return FakeCanvas {
        image = love.graphics.newImage(image:getData())
    }
end

function common.resizeCanvas(image, w, h, ox, oy)
    local canvas = love.image.newImageData(w, h)
    local ow, oh = image:getDimensions()
    canvas:paste(image:getData(), ox or 0, oy or 0, 0, 0, ow, oh)

    return FakeCanvas{
        image = love.graphics.newImage(canvas),
    } 
end

local draw = love.graphics.draw
function love.graphics.draw(image, ...)
    if not image.fake then
        draw(image, ...)
    else
        draw(image.image, ...)
    end
end

local newSB = love.graphics.newSpriteBatch
function love.graphics.newSpriteBatch(texture, ...)
    if not texture.fake then
        return newSB(texture, ...)
    else
        return newSB(texture.image, ...)
    end
end

function Brush.line(x1, y1, x2, y2, size, colour)
    local le = math.floor(size / 2)
    local re = size - le

    local w, h = math.abs(x2 - x1)+1, math.abs(y2 - y1)+1
    local x, y = math.min(x1, x2), math.min(y1, y2)

    print(w, h, size)

    local brush = Brush(w+size-1, h+size-1, false, colour or "erase")

    local bdata = brush.canvas:getData()
    
    local r, g, b, a = unpack(colour or {0, 0, 0, 0})
    local sx, sy = x1+le, y1+le
    local ex, ey = x2+le, y2+le

    for lx, ly in bresenham.line(sx, sy, ex, ey) do
        for py=0,size-1 do
            for px=0,size-1 do
                bdata:setPixel(lx - x - le + px, ly - y - le + py, r, g, b, a)
            end
        end
    end

    brush.canvas.image = love.graphics.newImage(bdata)

    LASTBRUSH = brush.canvas.image

    return brush, x-le, y-le
end

function blit(source, destination, ...)
    return destination:blit(source, ...)
end

function Brush:apply(canvas, quad, bx, by)
    LASTBRUSH = self.canvas

    local cdata = canvas:getData()
    local cw, ch = canvas:getDimensions()

    local bdata = self.canvas:getData()
    local bw, bh = self.canvas:getDimensions()

    if not quad then
        quad = love.graphics.newQuad(0, 0, bw, bh, bw, bh)
    end

    local qx, qy, qw, qh = quad:getViewport()

    local dx1, dy1 = math.max(qx, 0), math.max(qy, 0)
    local dx2, dy2 = math.min(qx+qw, bw), math.min(qy+qh, bh)

    quad:setViewport(dx1, dy1, dx2 - dx1, dy2 - dy1)

    print("VIEWPORT", quad:getViewport())

    blit(bdata, cdata, quad, bx+dx1-qx, by+dy1-qy, self.mode == "erase" and "multiplicative")

    quad:setViewport(qx, qy, qw, qh)

    canvas.image = love.graphics.newImage(cdata)
end

local function canvasFromImage(image)
    local canvas = love.graphics.newCanvas(image:getDimensions())

    canvas:renderTo(function()
        love.graphics.setBlendMode("premultiplied")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(image, 0, 0)
    end)

    return canvas
end

local function resizeCanvas(image, w, h, ox, oy)
    local canvas = love.graphics.newCanvas(w, h)

    canvas:renderTo(function()
        love.graphics.setBlendMode("premultiplied")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(image, ox, oy)
    end)

    return canvas
end

local function expandRectangle(rect_a, rect_b)
    local ax, ay, aw, ah = unpack(rect_a)
    local bx, by, bw, bh = unpack(rect_b)

    local cx = math.min(ax, bx)
    local cy = math.min(ay, by)
    local cw = math.max(ax + aw, bx + bw) - cx
    local ch = math.max(ay + ah, by + bh) - cy

    return {cx, cy, cw, ch}
end

return {
    textbox = textbox,

    canvasFromImage = canvasFromImage,
    
    loadCanvas = function(...) 
        return canvasFromImage(love.graphics.newImage(...))
    end,

    cloneCanvas = canvasFromImage,
    resizeCanvas = resizeCanvas,
    expandRectangle = expandRectangle,
}

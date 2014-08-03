local function canvasFromImage(image)
    local canvas = love.graphics.newCanvas(image:getDimensions())

    canvas:renderTo(function()
        love.graphics.setBlendMode("premultiplied")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(image, 0, 0)
    end)

    return canvas
end

return {
    textbox = textbox,

    canvasFromImage = canvasFromImage,
    
    loadCanvas = function(...) 
        return canvasFromImage(love.graphics.newImage(...))
    end,
}

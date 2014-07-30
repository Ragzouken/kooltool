local bresenham = {}

function bresenham.line(bx, by, ex, ey)
    return coroutine.wrap(function()
        local dx, dy = math.abs(ex - bx), math.abs(ey - by)
        local cx, cy = bx < ex and 1 or -1, by < ey and 1 or -1
        local error = dx - dy

        coroutine.yield(bx, by)

        while bx ~= ex or by ~= ey do
            local error2 = error * 2 

            if error2 > -dy then
                error = error - dy
                bx = bx + cx
            end

            if error2 < dx then
                error = error + dx
                by = by + cy
            end

            coroutine.yield(bx, by)
        end
    end)
end

return bresenham

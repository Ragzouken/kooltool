local wrap = {}

function wrap.wrap(font, text, width)
    local lines = {}
    local left = 1
    local split = false
    local right = 1

    while right < #text do
        if text:sub(right, right) == " " then
            split = right
        end

        if font:getWidth(text:sub(left, right+1)) > width then
            local cut = split or right

            table.insert(lines, text:sub(left, cut))

            left, right = cut, cut
            split = false
        else
            right = right + 1
        end
    end

    table.insert(lines, text:sub(left))

    return table.concat(lines, "\n"), lines
end

return wrap

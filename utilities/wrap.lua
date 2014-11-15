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

            left, right = cut + 1, cut + 1
            split = false
        else
            right = right + 1
        end
    end

    table.insert(lines, text:sub(left))

    return table.concat(lines, "\n"), lines
end

function wrap.cursor(lines, cursor)
    local cursor_lines = {}

    if cursor > 1 then print(#lines[1]) end

    for i, line in ipairs(lines) do
        if cursor >= 0 and cursor < #line then
            local left  = string.sub(line, 1, cursor):gsub(".", "_")
            local right = string.sub(line, cursor+2):gsub(".", "_")
            line = left .. "<" .. right
        elseif i == #lines and cursor == #line then
            line = line:gsub(".", "_") .. "<"
        else
            line = line:gsub(".", "_")
        end

        table.insert(cursor_lines, line)

        cursor = cursor - #line
    end

    return cursor_lines
end

return wrap

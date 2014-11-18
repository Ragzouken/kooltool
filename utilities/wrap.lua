local Class = require "hump.class"

local wrap = {}

local Text = Class {}
wrap.Text = Text

function Text:init(wrap)
    self.wrap = wrap

    self.text = ""
    self.cursor = 0
end

function Text:refresh()
    self.wrapped, self.lines = wrap.wrap2(self.text, self.wrap)
end

function Text:action(action)
        if action == "left"      then
        self.cursor = math.max(0, self.cursor - 1)
    elseif action == "right"     then
        self.cursor = math.min(self.cursor + 1, #self.text)
    elseif action == "backspace" then
    elseif action == "delete"    then
    elseif action == "newline"   then
    elseif action == "home"      then
        self.cursor = 0
    elseif action == "end"       then
        self.cursor = #self.text
    end
end

function Text:typed(text)
    self.text = string.format("%s%s%s",
                              self.text:sub(1, self.cursor),
                              text,
                              self.text:sub(self.cursor+1))

    self:refresh()
end

function wrap.wrap2(text, wrap)
    wrap = wrap or function() return false end

    local lines = {}
    local left = 1
    local split = false
    local right = 1

    while right < #text do
        local char = text:sub(right, right)
        local newline = char == "\n"

        if char == " " or newline then
            split = right
        end

        if wrap(text:sub(left, right+1)) or newline then
            local cut = split or right

            table.insert(lines, text:sub(left, newline and cut - 1 or cut ))

            left, right = cut + 1, cut + 1
            split = false
        else
            right = right + 1
        end
    end

    table.insert(lines, text:sub(left))

    return table.concat(lines, "\n"), lines
end

function wrap.wrap(font, text, width)
    local lines = {}
    local left = 1
    local split = false
    local right = 1

    while right < #text do
        local char = text:sub(right, right)

        if char == " " then
            split = right
        end

        if font:getWidth(text:sub(left, right+1)) > width or char == "\n" then
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

function wrap.cursor(text, cursor)
    local output = ""

    for i=1,#text+1 do
        local char = i <= #text and text:sub(i, i) or ""

        if char == "\n" and i == cursor + 1 then
            char = "<\n"
        elseif i == cursor + 1 then
            char = "<"
        elseif char ~= "\n" then
            char = "_"
        end

        output = output .. char
    end

    return output:split("\n")
end

return wrap

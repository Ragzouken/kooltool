local Class = require "hump.class"

local Notebox = Class {
    font = love.graphics.newFont("fonts/PressStart2P.ttf", 8)
}

Notebox.font:setFilter("linear", "nearest")

function Notebox:deserialise(data)
    self.x, self.y, self.text = unpack(data)
end

function Notebox:serialise()
    return {self.x, self.y, self.text}
end

function Notebox:init(x, y, text)
    self.x, self.y = x, y
    self.text = text or ""
end

function string:split(pat)
    local fields = {}
    local start = 1
    self:gsub("()("..pat..")", 
        function(c,d)
            table.insert(fields,self:sub(start,c-1))
            start = c + #d
        end
    )
    table.insert(fields, self:sub(start))
    return fields
end

function Notebox:draw()
    love.graphics.setFont(self.font)

    local lines = {}
    local width = 0

    --for line in string.gfind(self.text, "[^\n]+\n?") do
    --    lines[#lines+1] = line
    --    width = math.max(width, self.font:getWidth(line))
    --end

    for i, line in ipairs(self.text:split("\n")) do
        lines[#lines+1] = line
        width = math.max(width, self.font:getWidth(line))
    end

    local height = self.font:getHeight() * #lines
    local oy = self.font:getAscent() - self.font:getBaseline()

    local x, y = self.x - math.ceil(width / 2), self.y - math.ceil(height / 2)

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", x-1, y-1, width+2, height+2)

    love.graphics.setColor(255, 255, 255, 255)
    for i, line in ipairs(lines) do
        love.graphics.print(line, x, y + oy + (i - 1) * self.font:getHeight())
    end
end

function Notebox:keypressed(key)
    if key == "backspace" then self.text = string.sub(self.text, 1, #self.text-1) end
    if key == "return" then self.text = self.text .. "\n" end
end

function Notebox:textinput(character)
    self.text = self.text .. character
end

return Notebox

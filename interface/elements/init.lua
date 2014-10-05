local PATH = ...
local elements = {
    "Panel", "Button", "Radio", "Text",
    "shapes"
}

for i, name in ipairs(elements) do
    elements[name] = require (PATH .. "." .. name:lower())
end

return elements

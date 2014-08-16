--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]

--[[
Replaces several ImageData methods with FFI implementations. This can result
in a performance increase of up to 60x when calling the methods, especially
in simple code which had to fall back to interpreted mode specifically because
the normal ImageData methods couldn't be compiled by the JIT.
]]

--[[
NOTE: This was written specifically for LÖVE 0.9.0 and 0.9.1. Future versions
of LÖVE may change ImageData (either internally or externally) enough to cause
these replacements to break horribly.
]]

--[[
Unlike LÖVE's regular ImageData methods, these are *NOT THREAD-SAFE!*
You *need* to do your own synchronization if you want to use ImageData in
threads with these methods.
]]

assert(love and love.image, "love.image is required")
assert(jit, "LuaJIT is required")

local tonumber, assert = tonumber, assert

local ffi = require("ffi")

pcall(ffi.cdef, [[
typedef struct ImageData_Pixel
{
    uint8_t r, g, b, a;
} ImageData_Pixel;
]])

local pixelptr = ffi.typeof("ImageData_Pixel *")

local function inside(x, y, w, h)
    return x >= 0 and x < w and y >= 0 and y < h
end

local imagedata_mt
if debug then
    imagedata_mt = debug.getregistry()["ImageData"]
else
    imagedata_mt = getmetatable(love.image.newImageData(1,1))
end

local _getWidth = imagedata_mt.__index.getWidth
local _getHeight = imagedata_mt.__index.getHeight
local _getDimensions = imagedata_mt.__index.getDimensions

-- Holds ImageData objects as keys, and information about the objects as values.
-- Uses weak keys so the ImageData objects can still be GC'd properly.
local id_registry = {__mode = "k"}

function id_registry:__index(imagedata)
    local width, height = _getDimensions(imagedata)
    local pointer = ffi.cast(pixelptr, imagedata:getPointer())
    local p = {width=width, height=height, pointer=pointer}
    self[imagedata] = p
    return p
end

setmetatable(id_registry, id_registry)


-- FFI version of ImageData:mapPixel, with no thread-safety.
local function ImageData_FFI_mapPixel(imagedata, func, ix, iy, iw, ih)
    local p = id_registry[imagedata]
    local idw, idh = p.width, p.height
    
    ix = ix or 0
    iy = iy or 0
    iw = iw or idw
    ih = ih or idh
    
    assert(inside(ix, iy, idw, idh) and inside(ix+iw-1, iy+ih-1, idw, idh), "Invalid rectangle dimensions")
    
    local pixels = p.pointer
    
    for y=iy, iy+ih-1 do
        for x=ix, ix+iw-1 do
            local p = pixels[y*idw+x]
            local r, g, b, a = func(x, y, tonumber(p.r), tonumber(p.g), tonumber(p.b), tonumber(p.a))
            pixels[y*idw+x].r = r
            pixels[y*idw+x].g = g
            pixels[y*idw+x].b = b
            pixels[y*idw+x].a = a == nil and 255 or a
        end
    end
end

-- FFI version of ImageData:getPixel, with no thread-safety.
local function ImageData_FFI_getPixel(imagedata, x, y)
    local p = id_registry[imagedata]
    assert(inside(x, y, p.width, p.height), "Attempt to get out-of-range pixel!")
    
    local pixel = p.pointer[y * p.width + x]
    return tonumber(pixel.r), tonumber(pixel.g), tonumber(pixel.b), tonumber(pixel.a)
end

-- FFI version of ImageData:setPixel, with no thread-safety.
local function ImageData_FFI_setPixel(imagedata, x, y, r, g, b, a)
    a = a == nil and 255 or a
    local p = id_registry[imagedata]
    assert(inside(x, y, p.width, p.height), "Attempt to set out-of-range pixel!")
    
    local pixel = p.pointer[y * p.width + x]
    pixel.r = r
    pixel.g = g
    pixel.b = b
    pixel.a = a
end

-- FFI version of ImageData:getWidth.
local function ImageData_FFI_getWidth(imagedata)
    return id_registry[imagedata].width
end

-- FFI version of ImageData:getHeight.
local function ImageData_FFI_getHeight(imagedata)
    return id_registry[imagedata].height
end

-- FFI version of ImageData:getDimensions.
local function ImageData_FFI_getDimensions(imagedata)
    local p = id_registry[imagedata]
    return p.width, p.height
end

local function ImageData_FFI_blit(destination, source, quad, x, y, blend)
    local dest_r = id_registry[destination]
    local dw, dh = dest_r.width, dest_r.height

    local source_r = id_registry[source]
    local sw, sh = source_r.width, source_r.height
    
    local qx, qy, qw, qh = quad:getViewport()

    -- clip quad to destination
    if x < 0 then
        qw = qw - -x
        qx = qx + -x
        x = 0
    end

    if y < 0 then
        qh = qh - -y
        qy = qy + -y
        y = 0
    end

    -- clip quad to source
    -- how much to correct for top left corner out of bounds
    local dx, dy = qx >= 0 and 0 or -qx, qy >= 0 and 0 or -qy
    qx, qy, qw, qh = qx + dx, qy + dy, qw - dx, qh - dy

    -- bottom right corner clipping
    qw = math.min(qw, sw - qx, dw - x)
    qh = math.min(qh, sh - qy, dh - y)
    -- i removed -1 from sw - qx - 1 because brush sizes were 1 too large by accident

    if qx > sw-1 or qy > sh-1 -- quad beyond source bounds
    or qw <= 0   or qh <= 0   -- degenerate quad
    or  x > dw-1 or  y > dh-1 -- draw beyond destination bounds
    then return end

    local idw, idh = dw, dh
    
    ix = x or 0
    iy = y or 0
    iw = qw --or idw
    ih = qh --or idh

    assert(inside(ix, iy, idw, idh) and inside(ix+iw-1, iy+ih-1, idw, idh), "Invalid rectangle dimensions")

    local dest_pixels = dest_r.pointer

    for py=iy, iy+ih-1 do
        for px=ix, ix+iw-1 do
            local p = dest_pixels[py*idw+px]
            local sx, sy = px-x+qx, py-y+qy
            local source_pixel = source_r.pointer[sy * source_r.width + sx]
            
            local sr, sg, sb, sa = tonumber(source_pixel.r), tonumber(source_pixel.g), tonumber(source_pixel.b), tonumber(source_pixel.a)
            local dr, dg, db, da = tonumber(p.r), tonumber(p.g), tonumber(p.b), tonumber(p.a)
            local r, g, b, a

            if blend == "multiplicative" then
                r, g, b, a = sr * dr, sg * dg, sb * db, sa * da
            elseif sa > 128 then
                r, g, b, a = sr, sg, sb, sa
            else
                r, g, b, a = dr, dg, db, da
            end

            dest_pixels[py*idw+px].r = r
            dest_pixels[py*idw+px].g = g
            dest_pixels[py*idw+px].b = b
            dest_pixels[py*idw+px].a = a == nil and 255 or a
        end
    end
end

-- Overwrite love's functions with the new FFI versions.
imagedata_mt.__index.mapPixel = ImageData_FFI_mapPixel
imagedata_mt.__index.getPixel = ImageData_FFI_getPixel
imagedata_mt.__index.setPixel = ImageData_FFI_setPixel
imagedata_mt.__index.getWidth = ImageData_FFI_getWidth
imagedata_mt.__index.getHeight = ImageData_FFI_getHeight
imagedata_mt.__index.getDimensions = ImageData_FFI_getDimensions
imagedata_mt.__index.blit = ImageData_FFI_blit

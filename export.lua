local function copyFile(source, destination)
    local contents = love.filesystem.read(source)
    love.filesystem.write(destination, contents)
end

local function copyDirectory(source, destination, blacklist)
    local writing = {}

    love.filesystem.getDirectoryItems(source or "", function(filename)
        local path

        if source then
            path = source .. "/" .. filename
        else
            path = filename
        end

        if filename == "bresenham.lua" then print("FOUND IT THO") end

        if blacklist and blacklist[path] then
        elseif love.filesystem.isDirectory(path) then
            local dest = destination .. "/" .. filename
            love.filesystem.createDirectory(dest)
            copyDirectory(path, dest)
        elseif filename:sub(#filename-2, #filename) ~= ".db" then
            local dest = destination .. "/" .. filename
            local contents, size = love.filesystem.read(path)
            
            local wrote = love.filesystem.write(dest, contents)
            if not wrote then writing[dest] = contents end
        end
    end)

    local missing

    repeat
        missing = false
        local missed = {}

        for file, contents in pairs(writing) do
            print("missed ", file, #contents)
            local wrote = love.filesystem.write(file, contents)
            if not wrote then missing[file] = contents end
            missing = true
        end

        writing = missed
    until not missing
end

local function removeDirectory(directory)
    love.filesystem.getDirectoryItems(directory, function(filename)
        local path = directory .. "/" .. filename

        if love.filesystem.isDirectory(path) then
            removeDirectory(path)
        else
            love.filesystem.remove(path)
        end
    end)

    love.filesystem.remove(directory)
end

local exporters = {}

function exporters.Windows(name)
    local saves = love.filesystem.getSaveDirectory()
    local release = saves .. "/releases/" .. name

    local full = saves .. "/releases"
    local relative = "releases"

    local _7zip = full .. "/7za.exe"

    local zip = _7zip:gsub("/", "\\") .. " -tzip a " .. full .. "/" .. name .. "-love.zip " .. full .. "/" .. name .. "-love/*"
    local compile = "copy /b " .. full:gsub("/", "\\") .. "\\" .. name .. "\\love.exe+" .. full:gsub("/", "\\") .. "\\" .. name .. "-love.zip " .. full:gsub("/", "\\") .. "\\" .. name .. "\\" .. name .. ".exe"
    local bundle_win = _7zip:gsub("/", "\\") .. " -tzip a " .. full .. "/" .. name .. ".zip " .. full .. "/" .. name
    local bundle_osx = _7zip:gsub("/", "\\") .. " -tzip a " .. full .. "/" .. name .. ".app.zip " .. full .. "/" .. name .. ".app"

    copyFile("7za.exe", relative .. "/7za.exe")    
    os.execute(zip .. " 1> nul")
    copyFile(relative .. "/" .. name .. "-love.zip", relative .. "/" .. name .. ".love")
    love.filesystem.createDirectory("releases/" .. name)
    copyDirectory("love-binary-win", "releases/" .. name)
    os.execute(compile)
    love.filesystem.remove(relative .. "/" .. name .. "/love.exe")
    os.execute(bundle_win .. " 1> nul")

    copyDirectory("love-binary-osx", "releases/" .. name .. ".app")
    copyFile(relative .. "/" .. name .. "-love.zip", relative .. "/" .. name .. ".app/Contents/Resources/kooltool.love")
    os.execute(bundle_osx .. " 1> nul")
    removeDirectory(relative .. "/" .. name .. ".app")
    
    removeDirectory(relative .. "/" .. name)
    removeDirectory(relative .. "/" .. name .. "-love")
    love.filesystem.remove(relative .. "/7za.exe")
    love.filesystem.remove(relative .. "/" .. name .. "-love.zip")
end

exporters["OS X"] = function(release)
    love.filesystem.write("releases/export-not-supported-on-osx-yet.txt", "sorry")
end

function exporters.Linux(name)
    love.filesystem.write("releases/export-not-supported-on-linux-yet.txt", "sorry")
end

local function export(project)
    local blacklist = {
        ["tutorial"] = true,
        ["notes"] = true,
        [".git"] = true,
        ["projects"] = true,
        ["releases"] = true,
        ["love-binary-win"] = true,
        ["love-binary-osx"] = true,
        ["7za.exe"] = true
    }

    local name = project.name:gsub(" ", "_")

    love.filesystem.createDirectory("releases")
    copyDirectory(nil, "releases/" .. name .. "-love", blacklist)
    copyDirectory("projects/" .. name, "releases/" .. name .. "-love/embedded")

    exporters[love.system.getOS()](name)
end

return {
    export = export,
}

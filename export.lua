local function copyFile(source, destination)
    local contents = love.filesystem.read(source)
    love.filesystem.write(destination, contents)
end

local function copyDirectory(source, destination, blacklist)
    love.filesystem.createDirectory(destination)

    local writing = {}

    love.filesystem.getDirectoryItems(source or "", function(filename)
        local path

        if source then
            path = source .. "/" .. filename
        else
            path = filename
        end

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
            local wrote, error = love.filesystem.write(file, contents)
            if not wrote then missed[file] = contents print(error) end
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

function exporters.Windows(saves, name)
    saves = saves:gsub("/", "\\")

    copyFile("export-resources/export-windows.bat", "releases/export-windows.bat")
    copyFile("export-resources/7za.exe", "releases/7za.exe")
    os.execute(saves .. "\\releases\\export-windows.bat " .. name .. " " .. saves)
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
        ["export-resources"] = true,
    }

    -- FAILS TO EMBED

    love.filesystem.createDirectory("releases")

    copyDirectory(nil, "releases/kooltool-player-love", blacklist)
    copyDirectory("export-resources/love-binary-win", "releases/love-binary-win")
    copyDirectory("export-resources/love-binary-osx", "releases/love-binary-osx")

    local saves = love.filesystem.getSaveDirectory()

    exporters[love.system.getOS()](saves, project.name)
end

return {
    export = export,
}

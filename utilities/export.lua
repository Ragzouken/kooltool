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

local exporters = {
    ["Windows"] = function(saves, name)
        saves = saves:gsub("/", "\\")

        copyFile("export-resources/export-windows.bat", "releases/export-windows.bat")
        copyFile("export-resources/7za.exe", "releases/7za.exe")
        os.execute(saves .. "\\releases\\export-windows.bat \"" .. name .. "\" " .. saves)
    end,

    ["OS X"] = function(saves, name)
        copyFile("export-resources/export-osx.sh", "releases/export-osx.sh")
        os.execute("chmod +x \"" .. saves .. "/releases/export-osx.sh\"")
        os.execute("sh \"" .. saves .. "/releases/export-osx.sh\" \"" .. name .. "\" \"" .. saves .. "\"")
    end,

    ["Linux"] = function(saves, name)
        copyFile("export-resources/export-linux.sh", "releases/export-linux.sh")
        os.execute("chmod +x \"" .. saves .. "/releases/export-linux.sh\"")
        os.execute("sh \"" .. saves .. "/releases/export-linux.sh\" \"" .. name .. "\" \"" .. saves .. "\"")
    end,
}

local function export(project_folder)
    print(project_folder)

    local blacklist = {
        ["tutorial"] = true,
        ["notes"] = true,
        [".git"] = true,
        ["projects"] = true,
        ["releases"] = true,
        ["export-resources"] = true,
    }

    love.filesystem.createDirectory("releases")
    love.filesystem.createDirectory("releases/" .. project_folder)

    copyDirectory(nil, "releases/kooltool-player-love", blacklist)
    copyDirectory("export-resources/love-binary-win", "releases/love-binary-win")
    copyDirectory("export-resources/love-binary-osx", "releases/love-binary-osx")

    local saves = love.filesystem.getSaveDirectory()

    exporters[love.system.getOS()](saves, project_folder)

    love.system.openURL("file://" .. love.filesystem.getSaveDirectory() .. "/releases/" .. project_folder)
end

do
    require "love.filesystem"
    require "love.system"

    export(...)
end

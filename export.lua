local function copyDirectory(source, destination, blacklist)
    print("searching ", source)

    love.filesystem.getDirectoryItems(source, function(filename)
        local path = source .. "/" .. filename

        if blacklist[path] then
        elseif love.filesystem.isDirectory(path:sub(3,#path)) then
            local next = destination .. "/" .. path:sub(3,#path)
            love.filesystem.createDirectory(next)
            print("creating", next)
            copyDirectory(source .. "/" .. filename, dest)
        else
            local dest = destination .. "/" .. path:sub(3,#path)
            local contents, size = love.filesystem.read(path:sub(3,#path))
            love.filesystem.write(dest, contents)

            print("copying file", path)
        end
    end)
end

local function export(project)
    love.filesystem.mount(".", "projects")

    local blacklist = {
        "tutorial",
        "notes",
        ".git",
    }

    love.filesystem.getDirectoryItems("projects", function(filename)
        if love.filesystem.isDirectory(filename) then
            blacklist["./" .. filename] = true
        end
    end)

    copyDirectory(".", "export_test", blacklist)
end

return {
    export = export,
}

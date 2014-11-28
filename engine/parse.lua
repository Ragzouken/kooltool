local parse = {}

function parse.tokenise(script)
    local tokens = {{}}

    local function add_token(type, token)
        table.insert(tokens[#tokens], {type, token})
    end

    local function new_line()
        table.insert(tokens, {})
    end

    local token = ""
    local string = false

    for c in (script .. "\n"):gmatch(".") do
        local valid = c:match("[%w_]")
        local quote = (c == "\"") or (c == "\'")
        local space = (c == " ")  or (c == "\n")
        local symbo = (c == "=")  or (c == ":")

        if string then
            if quote then
                add_token("text", token)
                token = ""
                string = false
            else
                token = token .. c
            end
        else
            if symbo then
                if #token > 0 then add_token("word", token) end
                add_token("symbol", c)
                token = ""
            elseif quote then
                string = true
            elseif space and #token > 0 then
                add_token("word", token)
                token = ""
            elseif valid then
                token = token .. c
            end
        end

        if c == "\n" then new_line() end
    end

    table.remove(tokens, #tokens)

    return tokens
end

local function unzip(list)
    return coroutine.wrap(function()
        for i, item in ipairs(list) do
            coroutine.yield(unpack(item))
        end
    end)
end

function parse.header(tokens)
    if #tokens < 2 or tokens[1][1] ~= "word" or tokens[2][2] ~= ":" then
        return print("incomplete header")
    end

    print("trigger: " .. tokens[1][2])

    if #tokens > 2 then
        if #tokens < 4 or tokens[3][1] ~= "word" or not (tokens[3][2] == "any" or tokens[3][2] == "all") then
            return print("expected any or all")
        end

        local combine = tokens[3][2]
        local conditions = {}
        local key, equals

        for i=4,#tokens do
            local type, token = unpack(tokens[i])

            if not key then
                if type == "word" then
                    key = token
                else
                    return print("expecting key in condition")
                end
            elseif not equals then
                if type == "word" then
                    table.insert(conditions, {key, "true"})
                    key = token
                elseif token == "=" then
                    equals = true
                else
                    return print("expecting equals or new key")
                end
            else
                if type == "word" then
                    table.insert(conditions, {key, token})
                    key, equals = nil, nil
                else
                    return print("expecting value to check")
                end
            end
        end

        if key then table.insert(conditions, {key, "true"}) end

        io.write("if " .. combine .. " of: ")

        for key, value in unzip(conditions) do
            io.write(key .. " is " .. value .. ", ")
        end

        print()
    end

    return parse.command
end

function parse.command(tokens)
    if #tokens < 1 or tokens[1][1] ~= "word" then
        return print("expecting command")
    end 

    if tokens[1][2] == "say" then
        if #tokens > 1 and tokens[2][1] == "text" then
            print("say: \"" .. tokens[2][2] .. "\"")
            return parse.options
        else
            return print("expecting text to say")
        end
    elseif tokens[1][2] == "set" then
        if #tokens > 1 and tokens[2][1] == "word" then
            if #tokens == 2 then
                print("set: " .. tokens[2][2] .. " to true")
            elseif #tokens == 4 and tokens[3][2] == "=" and tokens[4][1] == "word" then
                print("set: " .. tokens[2][2] .. " to " .. tokens[4][2])
            else
                return print("expecting value to set")
            end
        else
            return print("expecting memory to set")
        end
    elseif tokens[1][2] == "do" then
        if #tokens > 1 and tokens[2][1] == "word" then
            print("do: " .. tokens[2][2])
        else
            return print("expecting trigger")
        end
    elseif tokens[1][2] == "stop" then
        print("stop")
        return parse.comment
    else
        return print("expecting command")
    end

    return parse.command
end

function parse.options(tokens)
    if #tokens == 2 and tokens[1][1] == "text" then
        if tokens[2][1] == "word" then
            print("choosing \"" .. tokens[1][2] .. "\" triggers " .. tokens[2][2])
        else
            return print("expecting trigger for dialogue choice")
        end
    else
        return parse.command(tokens)
    end

    return parse.options
end

function parse.comment(tokens)
    return parse.comment
end

function parse.test(text)
    local tokens = parse.tokenise(text)
    local state = parse.header

    for i, line in ipairs(tokens) do
        if state then
            state = state(line)
        else
            print("couldn't parse")
            break
        end
    end
end

return parse

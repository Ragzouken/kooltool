local class = require "hump.class"
local json = require "utilities.dkjson"

local parts = {
    state = {{"any", "symbol", "!"}, {"one", "word"}, {"one", "symbol", "="}, {"one", "word"}},
    condition = {{"one", "word"}, {"some", "state"}},
    header = {{"any", "symbol", "!"}, {"one", "word"}, {"one", "symbol", ":"}, {"any", "condition"}},
    command = {{}},
}

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
        local valid = c:match("[%w_%^%?%.<>]")
        local quote = (c == "\"")
        local space = (c == " ")  or (c == "\n")
        local symbo = (c == "=")  or (c == ":") or (c == "!")

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

local function check(token, type, value)
    if not token then return false end
    return token[1] == type and token[2] == value
end

function parse.header(tokens, action)
    local next = 1
    local global_trigger

    if check(tokens[1], "symbol", "!") then
        next = 2
        global_trigger = true
    end

    if #tokens <= next or tokens[next][1] ~= "word" or not check(tokens[next+1], "symbol", ":") then
        return false, "incomplete header"
    end

    action.trigger = {tokens[next][2], global_trigger}

    next = next + 2

    if #tokens >= next then
        if not check(tokens[next], "word", "any") and not check(tokens[next], "word", "all") then
            return false, "expected any or all"
        end

        local combine = tokens[next][2]
        local conditions = {}
        local key, equals, global

        next = next + 1

        for i=next,#tokens do
            local type, token = unpack(tokens[i])

            if not key then
                if type == "symbol" then
                    if token == "!" then
                        global = true
                    else
                        return false, "expecting !global or no symbol"
                    end
                elseif type == "word" then
                    key = token
                else
                    return false, "expecting key in condition"
                end
            elseif not equals then
                if type == "word" or check("symbol", "!") then
                    table.insert(conditions, {key, "yes", global})
                    key = (type == "word") and token
                    global = true
                elseif token == "=" then
                    equals = true
                else
                    return false, "expecting equals or new key"
                end
            else
                if type == "word" then
                    table.insert(conditions, {key, token, global})
                    key, equals = nil, nil
                else
                    return false, "expecting value to check"
                end
            end
        end

        if key then table.insert(conditions, {key, "yes", global}) end

        action.combine = combine
        action.conditions = conditions
    end

    return parse.command
end

function parse.command(tokens, action)
    action = action or ACTION

    if #tokens < 1 or tokens[1][1] ~= "word" then
        return false, "expecting command"
    end 

    local command = tokens[1][2]

    if command == "say" then
        if #tokens > 1 and tokens[2][1] == "text" then
            table.insert(action.commands, {"say", tokens[2][2], {}})
            return parse.options
        else
            return false, "expecting text to say"
        end
    elseif command == "set" then
        if #tokens > 1 then
            local next = 2
            local global

            if check(tokens[next], "symbol", "!") then
                next = 3
                global = true
            end 

            if #tokens < next or tokens[next][1] ~= "word" then return false, "expecting name to set" end

            if #tokens == next then
                table.insert(action.commands, {"set", tokens[next][2], "yes", global})
            elseif #tokens == next + 2 and tokens[next+1][2] == "=" and tokens[next+2][1] == "word" then
                table.insert(action.commands, {"set", tokens[next][2], tokens[next+2][2], global})
            else
                return false, "expecting value to set"
            end
        else
            return false, "expecting memory to set"
        end
    elseif command == "do" then
        if #tokens > 1 and tokens[2][1] == "word" then
            table.insert(action.commands, {"do", tokens[2][2]})
        else
            return false, "expecting event name"
        end
    elseif command == "move" then
        if #tokens > 2 then
            table.insert(action.commands, {"move", tokens[2][2], tokens[3] and tokens[3][2]})
        else
            return false, "expecting path"
        end
    elseif command == "trigger" then
        local trigger, global
        local next = 2

        if #tokens > 2 and tokens[2][1] == "symbol" and tokens[2][2] == "!" then
            global = true
            next = 3
        end

        if #tokens >= next and tokens[next][1] == "word" then
            local delay = #tokens >= next + 1 and tonumber(tokens[next + 1][2])

            if #tokens >= next + 1 and not tonumber(tokens[next + 1][2]) then
                return false, "expending delay as number"
            end

            table.insert(action.commands, {"trigger", tokens[next][2], delay, global})
        else
            return false, "expecting event name"
        end
    elseif command == "stop" then
        table.insert(action.commands, {"stop"})
        return parse.comment
    elseif command == "warp" then
        if #tokens == 2 and tokens[2][1] == "word" then
            table.insert(action.commands, {"warp", tokens[2][2]})
        else
            return false, "expecting label"
        end
    else
        return false, "expecting command"
    end

    return parse.command
end

function parse.options(tokens, action)
    if #tokens > 1 and tokens[1][1] == "text" then
        local global
        local next = 2

        if check(tokens[next], "symbol", "!") then
            next = 3
            global = true
        end 

        if tokens[next][1] == "word" then
            table.insert(action.commands[#action.commands][3], {tokens[1][2], tokens[next][2], global})
        else
            return false, "expecting trigger for dialogue choice"
        end
    else
        return parse.command(tokens)
    end

    return parse.options
end

function parse.comment(tokens, action)
    return parse.comment
end

ACTION = {}

function parse.test(text)
    local tokens = parse.tokenise(text)
    local state = parse.header
    local action = {
        conditions = {},
        commands = {},
    }

    ACTION = action

    local error

    for i, line in ipairs(tokens) do
        if state then
            state, error = state(line, action)
        else
            break
        end
    end

    if state and false then
        local label, global = unpack(action.trigger)
        print("trigger on " .. (label or "nothing") .. (global and " (global)" or ""))
        if action.combine then
            io.write("if " .. action.combine .. " of ")
            for key, value, global in unzip(action.conditions) do
                local tag = global and " (global)" or ""

                io.write(key .. tag .. " is " .. value .. ", ")
            end
            print()
        end
        print("actions")
        for i, command in pairs(action.commands) do
            local type = command[1]

            if type == "stop" then print("stop") end
            if type == "trigger" then 
                local delay = command[3] and " (" .. tonumber(command[3]) .. " delay)" or ""
                local scope = command[4] and " (global)" or ""

                print("trigger " .. command[2] .. scope .. delay)
            end
            if type == "do" then print("do " .. command[2]) end
            if type == "set" then 
                local scope = command[4] and " (global)" or ""
                print("set " .. command[2] .. scope .. " to " .. command[3]) 
            end
            if type == "say" then
                local options = command[3]

                if #options > 0 then
                    print("prompt with \"" .. command[2] .. "\"")
                    for choice, label in unzip(options) do
                        print("choosing \"" .. choice .. "\" triggers " .. label)
                    end 
                else
                    print("say \"" .. command[2] .. "\"")
                end
            end
        end
    end

    return state and action, error or "script understood"
end

return parse

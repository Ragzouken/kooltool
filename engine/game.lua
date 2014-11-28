local Class = require "hump.class"
local Camera = require "hump.camera"
local SparseGrid = require "utilities.sparsegrid"
local Player = require "engine.player"

local parse = require "engine.parse"
local json = require "utilities.dkjson"

function parse_note(text)
    local code = string.match(text, "%[(.+)%]")

    if code then
        local key, value

        if code:find("=") then
            key, value = string.match(code, "(.*)=(.*)")
        else
            key, value = code, true
        end

        return key:lower(), value
    end
end

local Game = Class {}

function Game:init(project, playtest)
    self.project = project
    self.camera = Camera(128, 128, 2)
    self.playtest = playtest
    self.tags = {}

    self.events = {}
    self.queue = {}
    self.active = {}
    self.globals = {}

    local layers = self.project.layers

    for notebox in pairs(layers.annotation.noteboxes) do
        local key, value = parse_note(notebox.text)

        if key then self.tags[key] = value end

        local action = parse.test(notebox.text)

        if action then
            self.events[action.trigger] = self.events[action.trigger] or {}
            table.insert(self.events[action.trigger], action)
        else
            print("invalid action")
        end
    end

    local tw, th = unpack(layers.surface.tileset.dimensions)

    self.actors = {}
    self.occupied = SparseGrid(tw, th)

    local function round(value, resolution)
        return math.floor(value * resolution) / resolution
    end

    local choice = {}

    for entity in pairs(layers.surface.entities) do
        local actor = Player(self, entity)
        self.actors[actor] = true

        table.insert(choice, actor)

        local px, py = entity.x, entity.y
        local x, y = round(px, 1/tw)+tw/2, round(py, 1/th)+th/2
        entity:move_to { x = x, y=y }

        if actor.tags.player then
            self.player = actor
        end
    end

    if #choice == 0 then
        self:undo()
        MODE = EDITOR
        return
    end

    if not self.player then 
        self.player = choice[love.math.random(#choice)]
    end

    self:trigger("start")
end

local function unzip(list)
    return coroutine.wrap(function()
        for i, item in ipairs(list) do
            coroutine.yield(unpack(item))
        end
    end)
end

function Game:check(action)
    local passed = 0

    for key, value in unzip(action.conditions) do
        if self.globals[key] == value then
            passed = passed + 1
        end
    end

    if not action.combine
    or (action.combine == "any" and passed > 0)
    or (action.combine == "all" and passed == #action.conditions) then
        return true
    end

    return false
end

function Game:trigger(event)
    for i, action in ipairs(self.events[event] or {}) do
        if self:check(action) then
            table.insert(self.queue, action.commands)
        end
    end
end

local speech = love.audio.newSource("sounds/tempspeech.wav")

function Game:process()
    while #self.active > 0 do
        local stack = {table.remove(self.active, 1)}

        while #stack > 0 do
            local commands = stack[1]

            for i, command in ipairs(commands) do
                if command[1] == "say" then
                    speech:stop()
                    speech:play()

                    self.TEXT = command[2]

                    local options = command[3]

                    if #options > 0 then
                        self.OPTIONS = {}
                        self.TEXT = self.TEXT .. "\n"

                        for i, option in ipairs(options) do
                            self.TEXT = self.TEXT .. "\n" .. tonumber(i) .. ". " .. option[1]
                            self.OPTIONS[i] = option[2]
                        end
                    end                    
                elseif command[1] == "stop" then 
                    stack = {}
                elseif command[1] == "trigger" then
                    self:trigger(command[2])
                elseif command[1] == "do" then
                    --if self:check()
                elseif command[1] == "set" then
                    self.globals[command[2]] = command[3]
                end
            end

            table.remove(stack)
        end
    end

    self.queue, self.active = {}, self.queue
end

function Game:update(dt)
    if not self.TEXT then
        for actor in pairs(self.actors) do
            if actor.active then
                self.occupied:set(nil, actor.tx, actor.ty)
                actor:update(dt)
                self.occupied:set(actor, actor.tx, actor.ty)
            end
        end

        self:process()
        self:trigger("updated")
    end

    if self.player then
        self.camera.x, self.camera.y = self.player.entity.x, self.player.entity.y
    end
end

function Game:destroy()
    
end

local font = love.graphics.newFont("fonts/PressStart2P.ttf", 16)

local function box(message)
    love.graphics.setFont(font)

    local wrap = 512 - 16 * 8
    local w, h = font:getWrap(message, wrap)
    
    w, h = w + 16, (h + 2) * 16
    
    local sw, sh = love.window.getDimensions()
    local dx, dy = (sw - w) / 2, (sh - h) / 2

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setBlendMode("alpha")
    love.graphics.rectangle("fill", dx, dy, w, h)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf(message,
        dx + 16 + 1,
        dy + 16 + 4, wrap)
end

function Game:draw_tree(params)
    self.camera:attach()
    
    self.project:draw_tree {
        filters = {
            whitelist = (self.tags.commentary and { "annotation" } or {}),
            blacklist = { "editor" },
        }
    }
    
    self.camera:detach()

    if self.TEXT then
        box(self.TEXT)
    end
end

function Game:undo()
    for actor in pairs(self.actors) do
        actor.entity:move_to { x = actor.ox,  y = actor.oy }
        actor.entity.a = 0
        actor.entity.active = true
    end
end

function Game:mousepressed(x, y, button)
end

function Game:mousereleased(x, y, button)
end

function Game:keypressed(key, isrepeat)
    if not isrepeat then self.TEXT = nil end
end

function Game:keyreleased(key)
end

function Game:textinput(character)
end

return Game

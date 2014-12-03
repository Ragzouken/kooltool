local Class = require "hump.class"
local Timer = require "hump.timer"
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

    self.timer = Timer()

    self.events = {}
    self.queue = {}
    self.active = {}
    self.globals = {}

    local layers = self.project.layers

    for notebox in pairs(layers.annotation.noteboxes) do
        local action = parse.test(notebox.text)

        if action then
            action.locals = self.globals

            local label, global = unpack(action.trigger)
            local events = self.events

            events[label] = events[label] or {}
            table.insert(events[label], action)
        else
            print("invalid action") print(notebox.text)
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

    for actor in pairs(self.actors) do
        actor:trigger("start")
    end

    self:process()
    self:process()
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

    for key, value, global in unzip(action.conditions) do
        local vars = global and self.globals or action.locals

        if vars[key] == value then
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
            table.insert(self.queue, action)
        end
    end
end

local speech = love.audio.newSource("sounds/tempspeech.wav")

function Game:process()
    while #self.active > 0 do
        local stack = {table.remove(self.active, 1)}

        while #stack > 0 do
            local action = stack[1]

            for i, command in ipairs(action.commands) do
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
                            self.OPTIONS[i] = {option[2], option[3] and self or action.entity}
                        end
                    end                    
                elseif command[1] == "stop" then 
                    stack = {}
                elseif command[1] == "trigger" then
                    local event = command[2]
                    local target = not command[4] and action.entity or self

                    if command[3] then
                        self.timer:add(command[3] / 10, function() target:trigger(event) end)
                    else
                        target:trigger(event)
                    end
                elseif command[1] == "do" then
                    --if self:check()
                elseif command[1] == "set" then
                    local type, key, value, global = unpack(command)
                    local vars = global and self.globals or action.locals

                    vars[key] = value
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

        self.timer:update(dt)
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
            whitelist = (self.globals.commentary and { "annotation" } or {}),
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
    if self.OPTIONS then
        for i, option in ipairs(self.OPTIONS) do
            if key == tostring(i) then
                self.OPTIONS = nil
                self.TEXT = nil
                option[2]:trigger(option[1])
            end
        end
    else
        if not isrepeat then self.TEXT = nil end
    end
end

function Game:keyreleased(key)
end

function Game:textinput(character)
end

return Game

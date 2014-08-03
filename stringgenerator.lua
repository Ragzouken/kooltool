-- http://www.roguebasin.com/index.php?title=Names_from_a_high_order_Markov_Process_and_a_simplified_Katz_back-off_scheme

local Class = require "hump.class"

local Categorical = Class {}

function Categorical:init(support, prior)
    self.counts = {}
    self.total = 0

    for event in pairs(support) do
        self.counts[event] = prior
        self.total = self.total + prior
    end
end

function Categorical:observe(event, count)
    self.counts[event] = self.counts[event] + (count or 1)
    self.total = self.total + (count or 1)
end

function Categorical:sample()
    local sample = love.math.random() * self.total

    for event, count in pairs(self.counts) do
        if sample <= count then
            return event
        end

        sample = sample - count
    end
end

local MarkovModel = Class {}

function MarkovModel:init(support, order, prior, boundary_symbol)
    self.boundary = boundary_symbol or "@"

    self.support = support
    self.support[self.boundary] = self.boundary
    self.order = order
    self.prior = prior
    self.boundary = self.boundary
    self.counts = {}

    self.prefix = string.rep(self.boundary, order)
    self.postfix = self.boundary
end

function MarkovModel:_categorical(context)
    if not self.counts[context] then
        self.counts[context] = Categorical(self.support, self.prior)
    end

    return self.counts[context]
end

function MarkovModel:_backoff(context)
    if #context > self.order then
        context = string.sub(context, #context-self.order+1, #context)
    elseif #context < self.order then
        context = string.rep(self.boundary, self.order - #context) .. context
    end

    while not self.counts[context] and #context > 0 do
        context = string.sub(context, 2, #context)
    end

    return context 
end

function MarkovModel:observe(sequence, count)
    sequence = self.prefix .. sequence .. self.postfix

    for i=self.order,#sequence-1 do
        local context = string.sub(sequence, i - self.order + 1, i)
        local event = string.sub(sequence, i+1, i+1)

        for j=1,#context do
            local categorical = self:_categorical(string.sub(context, j, #context))
            categorical:observe(event, count)
        end
    end
end

function MarkovModel:sample(context)
    context = self:_backoff(context)
    return self:_categorical(context):sample()
end

function MarkovModel:generate()
    local sequence = self:sample(self.prefix)

    while string.sub(sequence, #sequence, #sequence) ~= self.boundary do
        sequence = sequence .. self:sample(sequence)
    end

    return string.sub(sequence, 1, #sequence - 1)
end

local function StringGenerator(strings, order, prior)
    local names = {}
    local support = {}

    for i, name in ipairs(strings) do
        names[name] = name

        for j=1,#name do
            local char = string.sub(name, j, j)
            support[char] = true
        end
    end

    local model = MarkovModel(support, order or 3, prior or .001)
    for name in pairs(names) do model:observe(name) end

    return model
end

return StringGenerator

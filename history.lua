local Class = require "hump.class"

local History = Class {}

function History:init(limit)
    self.present = 1
    self.limit = limit
    self.events = {{}}
end

function History:alter()
    for i=self.present,#self.events do
        self.events[i] = nil
    end
end

function History:push(redo, undo, label)
    table.insert(self.events[self.present], {redo=redo, undo=undo, label=label})
    redo()
end

function History:bundle(label)
    self.events[self.present].label = label
    table.insert(self.events, {})
    self.present = #self.events
end

function History:undo()
    if self.present == 1 then return false end

    self.present = self.present - 1

    local bundle = self.events[self.present]

    print(bundle.label)

    for i=#bundle,1,-1 do
        bundle[i].undo()
    end

    return true
end

function History:redo()
    if self.present == #self.events then return false end

    local bundle = self.events[self.present]

    for i=1,#bundle do
        bundle[i].redo()
    end

    self.present = self.present + 1

    return true
end

return History

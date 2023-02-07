require "utils"

Hacking = {
    MAX = 100,
    SPEED_MULTIPLIER = 0.85,

    roots = nil,
    door = nil,
    progress = nil,
}
setup_class("Hacking")

function Hacking.new(roots, door)
    local obj = {}
    setup_instance(obj, Hacking)

    assert(roots ~= nil)
    obj.roots = roots
    obj.door = door
    obj.progress = 0

    return obj
end

function Hacking:get_progress()
    return math.min(Hacking.MAX, self.progress)
end

function Hacking:get_hacked_terminals()
    local hacked = {}
    for _, terminal in ipairs(self.roots.terminals) do
        if terminal.node ~= nil and not terminal.node.is_dead then
            table.insert(hacked, terminal)
        end
    end
    return hacked
end

function Hacking:update(dt)
    self.progress = self.progress + #self:get_hacked_terminals() * dt * Hacking.SPEED_MULTIPLIER
end

function Hacking:draw()
    if self:get_progress() == Hacking.MAX then
        return
    end

    local hacked_terminals = self:get_hacked_terminals()

    love.graphics.setColor({0.4, 0.8, 0.8, 0.2})
    love.graphics.setLineWidth(1)
    for _, terminal in ipairs(hacked_terminals) do
        love.graphics.line({terminal.x, terminal.y, self.door.x - 7, self.door.y - 22})
    end

    if #hacked_terminals > 0 then
        draw_text("Hacking door...", self.door.x, self.door.y - 48, {1, 1, 1, 1}, {0, 0, 0, 0.4})
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.rectangle("fill", self.door.x, self.door.y - 38, 90, 10)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("fill", self.door.x + 1, self.door.y - 37 + 1, 88 * self:get_progress() / Hacking.MAX, 6)
    end
end
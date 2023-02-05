require "utils"

Hacking = {
    MAX = 100,
    SPEED_MULTIPLIER = 0.5,

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

function Hacking:progress()
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
    local hacked_terminals = self:get_hacked_terminals()

    love.graphics.setColor({0, 0.4, 0.4, 0.2})
    love.graphics.setLineWidth(1)
    for _, terminal in ipairs(hacked_terminals) do
        love.graphics.line({terminal.x, terminal.y, self.door.x - 7, self.door.y - 22})
    end

    if #hacked_terminals > 0 then
        draw_text("Hacking doors...", self.door.x, self.door.y - 48, {1, 1, 1, 1}, {0, 0, 0, 0.4})
    end
end
require "utils"

Hacking = {
    MAX = 5,
    SPEED_MULTIPLIER = 1,

    progress = nil,
}
setup_class("Hacking")

function Hacking.new(roots)
    local obj = {}
    setup_instance(obj, Hacking)

    assert(roots ~= nil)
    obj.roots = roots
    obj.progress = 0

    return obj
end

function Hacking:progress()
    return math.min(Hacking.MAX, self.progress)
end

function Hacking:update(dt)
    local num_hacked = 0
    for _, terminal in ipairs(self.roots.terminals) do
        if terminal.node ~= nil and not terminal.node.is_dead then
            num_hacked = num_hacked + 1
        end
    end
    self.progress = self.progress + num_hacked * dt * Hacking.SPEED_MULTIPLIER
end
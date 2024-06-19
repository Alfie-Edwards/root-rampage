require "systems.branch"
require "systems.door"
require "systems.hacking"
require "systems.level"
require "systems.player"
require "systems.roots"
require "systems.terminal"
require "systems.tooltip"
require "systems.tree_spot"
require "systems.wincon"
GAME = {}

function GAME.update(state, inputs)
    timer:push("GAME.update")
    state.t = state.t + state.dt
    timer:push("ROOTS.update")
    ROOTS.update(state, inputs)
    timer:poppush(10, "BRANCH.update")
    BRANCH.update(state, inputs)
    timer:poppush(10, "TREE_SPOT.update")
    TREE_SPOT.update(state, inputs)
    timer:poppush(10, "TERMINAL.update")
    TERMINAL.update(state, inputs)
    timer:poppush(10, "PLAYER.update")
    PLAYER.update(state, inputs)
    timer:poppush(10, "HACKING.update")
    HACKING.update(state, inputs)
    timer:poppush(10, "TOOLTIP.update")
    TOOLTIP.update(state, inputs)
    timer:poppush(10, "WINCON.update")
    WINCON.update(state, inputs)
    timer:pop(10)
    timer:pop(state.dt * 1000)
end

function GAME.draw(state, inputs, dt)
    LEVEL.draw(state, inputs, dt)
    ROOTS.draw(state, inputs, dt)
    BRANCH.draw(state, inputs, dt)
    TERMINAL.draw(state, inputs, dt)
    TREE_SPOT.draw(state, inputs, dt)
    DOOR.draw(state, inputs, dt)
    PLAYER.draw(state, inputs, dt)
    HACKING.draw(state, inputs, dt)
    TOOLTIP.draw(state, inputs, dt)
    WINCON.draw(state, inputs, dt)
    -- state.nodes:draw(true, true, inputs.roots_pos_x, inputs.roots_pos_y)
end

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
    local timer = Timer()
    state.t = state.t + state.dt
    ROOTS.update(state, inputs)
    timer:report_and_reset("ROOTS", 10)
    BRANCH.update(state, inputs)
    timer:report_and_reset("BRANCH", 10)
    TREE_SPOT.update(state, inputs)
    timer:report_and_reset("TREE_SPOT", 10)
    TERMINAL.update(state, inputs)
    timer:report_and_reset("TERMINAL", 10)
    PLAYER.update(state, inputs)
    timer:report_and_reset("PLAYER", 10)
    HACKING.update(state, inputs)
    timer:report_and_reset("HACKING", 10)
    TOOLTIP.update(state, inputs)
    timer:report_and_reset("TOOLTIP", 10)
    WINCON.update(state, inputs)
    timer:report_and_reset("WINCON", 10)
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
    state.nodes:draw(true, true, inputs.roots_pos_x, inputs.roots_pos_y)
end

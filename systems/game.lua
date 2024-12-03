require "systems.branch"
require "systems.door"
require "systems.hacking"
require "systems.level"
require "systems.particle"
require "systems.player"
require "systems.powerups"
require "systems.roots"
require "systems.terminal"
require "systems.tooltip"
require "systems.tree_spot"
require "systems.wincon"
GAME = {}

function GAME.update(state, inputs)
    state.t = state.t + state.dt
    love.math.setRandomSeed(state.t * 1000)
    ROOTS.update(state, inputs)
    BRANCH.update(state, inputs)
    TREE_SPOT.update(state, inputs)
    TERMINAL.update(state, inputs)
    PARTICLE.update(state, inputs)
    PLAYER.update(state, inputs)
    POWERUPS.update(state, inputs)
    HACKING.update(state, inputs)
    TOOLTIP.update(state, inputs)
    WINCON.update(state, inputs)
end

function GAME.draw(state, inputs, dt)
    LEVEL.draw(state, inputs, dt)
    ROOTS.draw(state, inputs, dt)
    BRANCH.draw(state, inputs, dt)
    TERMINAL.draw(state, inputs, dt)
    TREE_SPOT.draw(state, inputs, dt)
    DOOR.draw(state, inputs, dt)
    PARTICLE.draw(state, inputs, dt)
    POWERUPS.draw(state, inputs, dt)
    PLAYER.draw(state, inputs, dt)
    HACKING.draw(state, inputs, dt)
    TOOLTIP.draw(state, inputs, dt)
    WINCON.draw(state, inputs, dt)
    -- state.nodes:draw(true, true, inputs.roots_pos_x, inputs.roots_pos_y)
end

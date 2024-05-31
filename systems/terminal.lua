require "sprite"
require "states.terminal"
require "systems.node"

TERMINAL = {
    RADIUS = 24,
    TIME = 5,
    TOOLTIP = "Hack terminal",
    TOOLTIP2 = "Gaining root access...",

    SPRITES = {
        unhacked = sprite.make_set("Terminal/", { "Terminal1","Terminal2" }),
        hacking = sprite.make_set("Terminal/", { "TerminalPlant1","TerminalPlant2" }),
        hacked = sprite.make_set("Terminal/", { "TerminalPlantFULLYHACKED1","TerminalPlantFULLYHACKED2" }),
    },

    GROW_DURATION = 2,
    WITHER_DURATION = 1,
    CYCLE_DURATION = 0.5,

    POSITIONS = {
        { x =  2.5, y =  2 },
        { x =  2.5, y = 24 },
        { x = 45.5, y =  2 },
        { x = 45.5, y = 24 },
        { x = 26.5, y =  8 },
        { x = 26.5, y = 17 },
    },
}

function TERMINAL.update(state, inputs)
    for _, terminal in ipairs(state.terminals) do
        if terminal.node ~= nil and terminal.node.is_dead then
            terminal.node = nil
            terminal.t_hacked = NEVER
            terminal.t_cut = state.t
        end
        if terminal.node ~= nil and terminal.t_hacked == NEVER then
            terminal.t_hacked = state.t
            terminal.t_cut = NEVER
        end
        if terminal.node == nil and
               state.roots.grow_node ~= nil and
               state.tooltip.message == nil and
               sq_dist(terminal.x, terminal.y, inputs.roots_pos_x, inputs.roots_pos_y) < TERMINAL.RADIUS ^ 2 then
            state.tooltip.message = TERMINAL.TOOLTIP
        end
    end
end

function TERMINAL.draw(state, inputs, dt)
    for _, terminal in ipairs(state.terminals) do
        local sprite = TERMINAL.sprite(terminal, state.t + dt)
        if sprite == nil then
            return
        end

        local ox = sprite:getWidth() / 2
        local oy = sprite:getHeight() / 2

        -- want to draw the sprite slightly above centre, since the 'ground' bit is near
        -- the bottom
        oy = oy - 5

        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.draw(sprite, terminal.x, terminal.y, 0, 1, 1, ox, oy)
    end
end

function TERMINAL.create_node(terminal, parent, state)
    assert(terminal.node == nil)
    terminal.node = NODE.add_node(terminal.x - 19, terminal.y - 8, parent, state, NODE_TYPE.TERMINAL)
    return terminal.node
end

function TERMINAL.sprite(terminal, t)
    if terminal.node ~= nil and terminal.t_hacked ~= NEVER then
        if (t - terminal.t_hacked) < TERMINAL.GROW_DURATION then
            return sprite.sequence(TERMINAL.SPRITES.hacking, TERMINAL.GROW_DURATION, t - terminal.t_hacked)
        else
            return sprite.cycling(TERMINAL.SPRITES.hacked, TERMINAL.CYCLE_DURATION, t)
        end
    elseif terminal.t_cut ~= NEVER and (t - terminal.t_cut) < TERMINAL.WITHER_DURATION then
        if terminal.t_hacked < TERMINAL.GROW_DURATION then
            return sprite.sequence(reverse(TERMINAL.SPRITES.hacking), TERMINAL.WITHER_DURATION, t - terminal.t_cut)
        else
            return sprite.cycling(TERMINAL.SPRITES.unhacked, TERMINAL.CYCLE_DURATION, t)
        end
    else
        return sprite.cycling(TERMINAL.SPRITES.unhacked, TERMINAL.CYCLE_DURATION, t)
    end

    return nil
end

function TERMINAL.find_terminal(terminals, x, y)
    for _, terminal in ipairs(terminals) do
        if terminal.node == nil and sq_dist(x, y, terminal.x, terminal.y) < TERMINAL.RADIUS ^ 2 then
            return terminal
        end
    end
    return nil
end

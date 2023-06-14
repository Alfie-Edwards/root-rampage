require "utils"
require "states.hacking"

HACKING = {
    MAX = 100,
    SPEED_MULTIPLIER = 0.85,
}

function HACKING.update(state, inputs)
    local hacking = state.hacking
    hacking.progress = hacking.progress +  state.dt * HACKING.get_progress_modifier(state)
end

function HACKING.draw(state, inputs, dt)
    local hacking = state.hacking

    local progress = hacking.progress + HACKING.get_progress_modifier(state) * dt
    if progress >= HACKING.MAX then
        return
    end

    local hacked_terminals = HACKING.get_hacked_terminals(state)

    love.graphics.setColor({0.4, 0.8, 0.8, 0.2})
    love.graphics.setLineWidth(1)
    for _, terminal in ipairs(hacked_terminals) do
        love.graphics.line({terminal.x, terminal.y, state.door.x - 7, state.door.y - 22})
    end

    if #hacked_terminals > 0 then
        draw_text("Hacking door...", state.door.x, state.door.y - 48, {1, 1, 1, 1}, {0, 0, 0, 0.4})
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.rectangle("fill", state.door.x, state.door.y - 38, 90, 10)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.setLineWidth(1)

        love.graphics.rectangle("fill", state.door.x + 1, state.door.y - 37 + 1, 88 * progress / HACKING.MAX, 6)
    end
end

function HACKING.get_progress_modifier(state)
    return #HACKING.get_hacked_terminals(state) * HACKING.SPEED_MULTIPLIER
end

function HACKING.get_hacked_terminals(state)
    local hacked = {}
    for _, terminal in ipairs(state.terminals) do
        if terminal.node ~= nil and not terminal.node.is_dead then
            table.insert(hacked, terminal)
        end
    end
    return hacked
end

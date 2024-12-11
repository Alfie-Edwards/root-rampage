require "states.wincon"
require "systems.hacking"
require "systems.level"

WINCON = {}

function WINCON.update(state, inputs)
    local wincon = state.wincon

    if state.newest_node ~= nil and NODE.is_dead(state, state.newest_node) then
        state.newest_node = nil
    end

    if not state.nodes:any() then
        WINCON.AxeManWins(wincon)
    end

    if state.hacking.progress >= HACKING.MAX and not state.door.is_open then
        DOOR.open(state.door, state.t)
    end

    if state.door.is_open then
        local door_pos = DOOR.get_center(state.door)
        local most_recent_node = NODE.from_id(state, state.newest_node)
        if most_recent_node ~= nil and (door_pos.x - most_recent_node.x) ^ 2 + (door_pos.y - most_recent_node.y) ^ 2 < (1.5 * LEVEL.cell_size() * LEVEL.cell_size()) then
            WINCON.RootsWin(wincon)
        end
    end
end

function WINCON.draw(state, inputs, dt)
    local wincon = state.wincon

    if not wincon.game_over then
        return
    end
    love.graphics.clear({0, 0, 0, 1})
    draw_centred_text(wincon.end_screen, canvas:width() / 2, canvas:height() / 2 - 16, font32, {1, 1, 1, 1})
    draw_centred_text("ESC to continue...", canvas:width() / 2, canvas:height() - 48, font16, {1, 1, 1, 0.5})
end

function WINCON.RootsWin(wincon)
    wincon.game_over = true
    wincon.end_screen = "ROOTS WIN"
end

function WINCON.AxeManWins(wincon)
    wincon.game_over = true
    wincon.end_screen = "AXE MAN WINS"
end

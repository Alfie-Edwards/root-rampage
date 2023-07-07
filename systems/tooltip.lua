require "systems.door"
require "systems.terminal"
require "systems.tree_spot"

TOOLTIP = {}

function TOOLTIP.update(state, inputs)
    local tooltip = state.tooltip
    local roots = state.roots

    tooltip.message = nil
    if roots.tree_spot ~= nil and roots.tree_spot.node == nil then
        if tooltip.timer == nil then
            tooltip.message = TREE_SPOT.TOOLTIP
        else
            tooltip.message = TREE_SPOT.TOOLTIP2
        end
    end

    if tooltip.message == nil then
        if roots.terminal ~= nil and roots.terminal.node == nil then
            if tooltip.timer == nil then
                tooltip.message = TERMINAL.TOOLTIP
            else
                tooltip.message = TERMINAL.TOOLTIP2
            end
        end
    end

    if tooltip.message == nil then
        local door_pos = DOOR.get_center(state.door)
        if sq_dist(inputs.roots_pos_x, inputs.roots_pos_y, door_pos.x, door_pos.y) < 32 ^ 2 then
            if state.door.is_open then
                tooltip.message = DOOR.TOOLTIP_OPEN
            else
                tooltip.message = DOOR.TOOLTIP_CLOSED
            end
        end
    end
end

function TOOLTIP.draw(state, inputs, dt)
    local tooltip = state.tooltip

    if tooltip.message ~= nil then
        draw_centred_text(tooltip.message, inputs.roots_pos_x, inputs.roots_pos_y - 10, {1, 1, 1, 1}, {0, 0, 0, 0.4})
    end

    if tooltip.timer ~= nil then
        local angle = math.min(1, (state.t + dt - tooltip.timer) / tooltip.duration) * math.pi * 2
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.circle("fill", inputs.roots_pos_x, inputs.roots_pos_y + 20, 12)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.arc("fill", inputs.roots_pos_x, inputs.roots_pos_y + 20, 10, -math.pi / 2, angle - math.pi / 2)
    end
end
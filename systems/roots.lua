require "utils"
require "states.roots"
require "systems.branch"
require "systems.level"
require "systems.node"
require "systems.terminal"
require "systems.tree_spot"

AttackState = {
    READY = 1,
    WINDUP = 2,
    ATTACKING = 3,
    COOLDOWN = 4,
}

ROOTS = {
    SPEED = 2,
    ATTACK_SPEED = 7,
    ATTACK_WINDUP_SPEED = 0.5,
    ATTACK_WINDUP_TIME = 0.3,
    ATTACK_TIME = 0.1,
    ATTACK_CD = 4,
    KILL_RADIUS = 12,
}

function ROOTS.get_attack_state(roots, t)
    if roots.t_attack == nil then
        return AttackState.READY
    elseif (t - roots.t_attack) < ROOTS.ATTACK_WINDUP_TIME then
        return AttackState.WINDUP
    elseif (t - roots.t_attack) < (ROOTS.ATTACK_WINDUP_TIME + ROOTS.ATTACK_TIME) then
        return AttackState.ATTACKING
    elseif (t - roots.t_attack) < (ROOTS.ATTACK_WINDUP_TIME + ROOTS.ATTACK_TIME + ROOTS.ATTACK_CD) then
        return AttackState.COOLDOWN
    else
        return AttackState.READY
    end
end

function ROOTS.update(state, inputs)
    local roots = state.roots
    local tooltip = state.tooltip

    if roots.selected ~= nil and roots.selected.is_dead then
        
        roots.selected = nil
    end

    local attack_state = ROOTS.get_attack_state(roots, state.t)

    if inputs.roots_grow or (inputs.roots_attack and attack_state == AttackState.ATTACKING) then
        if roots.selected == nil and roots.grow_node ~= nil and not roots.grow_node.is_dead then
            roots.selected = roots.grow_node
        end
    else
        roots.selected = nil
    end

    if inputs.roots_attack and attack_state == AttackState.READY and tooltip.timer == nil then
        roots.t_attack = state.t
        attack_state = ROOTS.get_attack_state(roots, state.t)
    end

    if roots.selected ~= nil and tooltip.timer == nil then
        roots.grow_node = roots.selected
    else
        roots.grow_node = NODE.get_closest_node(state, inputs.roots_pos_x, inputs.roots_pos_y)
    end

    if roots.grow_node == nil then
        roots.new_pos_x = nil
        roots.new_pos_y = nil
        return
    end

    if attack_state == AttackState.WINDUP then
        roots.speed = ROOTS.ATTACK_WINDUP_SPEED
    elseif attack_state == AttackState.ATTACKING then
        roots.speed = ROOTS.ATTACK_SPEED
    else
        roots.speed = ROOTS.SPEED
    end

    local v = Vector.new(roots.grow_node.x, roots.grow_node.y,
                         inputs.roots_pos_x, inputs.roots_pos_y)

    if v:length() == 0 then
        roots.new_pos_x = nil
        roots.new_pos_y = nil
        return
    end

    roots.new_pos_x = roots.grow_node.x + v:direction_x() * roots.speed
    roots.new_pos_y = roots.grow_node.y + v:direction_y() * roots.speed

    if v:length() < roots.speed then
        roots.valid = false
    elseif NODE.get_closest_node(state, roots.new_pos_x, roots.new_pos_y) ~= roots.grow_node then
        roots.valid = false
    elseif LEVEL.solid({x = roots.new_pos_x, y = roots.new_pos_y}) then
        roots.valid = false
    else
        roots.valid = true
    end

    if tooltip.timer == nil and not inputs.roots_attack then
        roots.tree_spot = TREE_SPOT.find_tree_spot(state.tree_spots, roots.new_pos_x, roots.new_pos_y)
        if roots.tree_spot ~= nil then
            if roots.selected ~= nil then
                tooltip.timer = state.t
                tooltip.duration = TREE_SPOT.TIME
            end
        else
            roots.terminal = TERMINAL.find_terminal(state.terminals, roots.new_pos_x, roots.new_pos_y)
            if roots.terminal ~= nil and roots.selected ~= nil then
                tooltip.timer = state.t
                tooltip.duration = TERMINAL.TIME
            end
        end
    else
        if roots.tree_spot ~= nil and (roots.tree_spot.node ~= nil or roots.selected == nil or inputs.roots_attack) then
            roots.tree_spot = nil
            tooltip.timer = nil
        end
        if roots.terminal ~= nil and (roots.terminal.node ~= nil or roots.selected == nil or inputs.roots_attack) then
            roots.terminal = nil
            tooltip.timer = nil
        end
    end

    if roots.selected ~= nil then
        if roots.valid then
            if roots.tree_spot ~= nil and roots.tree_spot.node == nil then
                if (state.t - tooltip.timer) > TREE_SPOT.TIME then
                    TREE_SPOT.create_node(roots.tree_spot, roots.selected, state)
                end
            elseif roots.terminal ~= nil and roots.terminal.node == nil then
                if (state.t - tooltip.timer) > TERMINAL.TIME then
                    TERMINAL.create_node(roots.terminal, roots.selected, state)
                end
            else
                roots.selected = NODE.add_node(roots.new_pos_x, roots.new_pos_y, roots.grow_node, state)
            end
        end
        if attack_state == AttackState.ATTACKING and
                sq_dist(state.player.pos.x, state.player.pos.y, roots.selected.x, roots.selected.y) < ROOTS.KILL_RADIUS ^ 2 then
            state.player.time_of_death = state.t
        end
    end
end

function ROOTS.draw(state, inputs, dt)
    local roots = state.roots
    local tooltip = state.tooltip

    if roots.grow_node ~= nil then
        local attack_state = ROOTS.get_attack_state(roots, state.t + dt)
        local color = nil
        if attack_state == AttackState.ATTACKING then
            color = {0.4, 0.08, 0.02, 1}
        end
        local v = Vector.new(roots.grow_node.x, roots.grow_node.y,
                             roots.new_pos_x, roots.new_pos_y)
        BRANCH.draw_spike(
            roots.grow_node.x,
            roots.grow_node.y,
            v:direction_x(),
            v:direction_y(),
            roots.speed, color)
    end

    if tooltip.timer ~= nil and roots.selected ~= nil then
        if roots.tree_spot ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({inputs.roots_pos_x, inputs.roots_pos_y + 20,
                                roots.tree_spot.x, roots.tree_spot.y})
            local v = Vector.new(roots.selected.x, roots.selected.y,
                                 roots.tree_spot.x, roots.tree_spot.y)
            BRANCH.draw_spike(
                roots.selected.x,
                roots.selected.y,
                v:direction_x(),
                v:direction_y(),
                ROOTS.SPEED)
        end

        if roots.terminal ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({inputs.roots_pos_x, inputs.roots_pos_y + 20,
                                roots.terminal.x, roots.terminal.y})
            local v = Vector.new(roots.selected.x, roots.selected.y,
                                 roots.terminal.x, roots.terminal.y)
            BRANCH.draw_spike(
                roots.selected.x,
                roots.selected.y,
                v:direction_x(),
                v:direction_y(),
                ROOTS.SPEED)
        end
    end
end

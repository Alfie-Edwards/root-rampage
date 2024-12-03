require "states.roots"
require "systems.branch"
require "systems.level"
require "systems.node"
require "systems.terminal"
require "systems.tree_spot"

AttackState = {
    READY = 1,
    CHARGING = 2,
    ATTACKING = 3,
    COOLDOWN = 4,
}

ROOTS = {
    SPEED = 120,
    ATTACK_SPEED = 480,
    ATTACK_TIME_MIN = 0.08,
    ATTACK_TIME_MAX = 0.16,
    ATTACK_CD = 4,
    STRIKE_MIN_CHARGE_T = 0.07,
    STRIKE_MAX_CHARGE_T = 0.16,
    KILL_RADIUS = 12,
    ATTACK_COLOR = {0.4, 0.08, 0.02, 1},
    CD_FLASH_COLOR = {1, 1, 1, 1},
    CD_FLASH_TIME = 0.2,
    CLOUD_RADIUS = 12,
    CLOUD_DURATION = 3,
}

function ROOTS.do_strike(roots, t_attack)
    assert(roots.t_charge ~= NEVER)
    t_attack = nil_coalesce(t_attack, roots.t_attack)
    return (t_attack - roots.t_charge) >= ROOTS.STRIKE_MIN_CHARGE_T
end

function ROOTS.strike_time(roots, t_attack)
    assert(roots.t_charge ~= NEVER)
    t_attack = nil_coalesce(t_attack, roots.t_attack)
    local k = clamp(((t_attack - roots.t_charge) - ROOTS.STRIKE_MIN_CHARGE_T) / (ROOTS.STRIKE_MAX_CHARGE_T - ROOTS.STRIKE_MIN_CHARGE_T), 0, 1)
    print(k)
    return lerp(ROOTS.ATTACK_TIME_MIN, ROOTS.ATTACK_TIME_MAX, k)
end

function ROOTS.get_attack_state(roots, t)
    local elapsed = t - roots.t_attack
    if roots.t_attack == NEVER then
        return AttackState.CHARGING
    end
    if ROOTS.do_strike(roots) then
        local strike_time = ROOTS.strike_time(roots)
        if elapsed > (strike_time + ROOTS.ATTACK_CD) then
            return AttackState.READY
        elseif elapsed > strike_time then
            return AttackState.COOLDOWN
        else
            return AttackState.ATTACKING
        end
    else
        if elapsed > ROOTS.ATTACK_CD then
            return AttackState.READY
        else
            return AttackState.COOLDOWN
        end
    end
end

function ROOTS.update(state, inputs)
    local roots = state.roots
    local tooltip = state.tooltip

    if roots.t_attack == NEVER and roots.t_charge == NEVER then
        roots.t_charge = -(ROOTS.ATTACK_CD + ROOTS.ATTACK_TIME_MIN + ROOTS.STRIKE_MIN_CHARGE_T)
        roots.t_attack = roots.t_charge + ROOTS.STRIKE_MIN_CHARGE_T
    end

    if roots.selected ~= nil and NODE.is_dead(state, roots.selected) then
        roots.selected = NONE
    end

    local attack_state = ROOTS.get_attack_state(roots, state.t)

    if inputs.roots_grow or attack_state == AttackState.ATTACKING then
        if roots.selected == nil and roots.grow_node ~= nil and not NODE.is_dead(state, roots.grow_node) then
            roots.selected = roots.grow_node
        end
    else
        roots.selected = NONE
        roots.grow_branch = NONE
    end

    if inputs.roots_attack then
        if attack_state == AttackState.READY and tooltip.timer == nil then
            roots.t_charge = state.t
            roots.t_attack = NEVER
            attack_state = AttackState.CHARGING
        end
    end

    if roots.selected ~= nil and tooltip.timer == nil then
        roots.grow_node = roots.selected
    else
        if not (inputs.roots_attack and not inputs.roots_grow and attack_state ~= AttackState.ATTACKING) then
            roots.grow_node = nil_coalesce(state.nodes:closest(inputs.roots_pos_x, inputs.roots_pos_y), NONE)
            roots.grow_branch = NONE
        end
    end

    if roots.grow_node == nil then
        roots.selected = NONE
        roots.grow_branch = NONE
        roots.new_pos_x = NONE
        roots.new_pos_y = NONE
        return
    end

    -- print(get_key(AttackState, attack_state), ROOTS.do_strike(roots), roots.t_attack, roots.t_charge)
    if attack_state == AttackState.CHARGING then
        if not inputs.roots_attack then
            roots.t_attack = state.t
            if not ROOTS.do_strike(roots) then
                PARTICLE.add_cloud(state, roots.grow_node.x, roots.grow_node.y, ROOTS.CLOUD_RADIUS, ROOTS.CLOUD_DURATION)
            end
        end
    elseif attack_state == AttackState.ATTACKING then
        roots.speed = ROOTS.ATTACK_SPEED
    else
        roots.speed = ROOTS.SPEED
    end

    local v = Vector(roots.grow_node.x, roots.grow_node.y,
                     inputs.roots_pos_x, inputs.roots_pos_y)
    local sqln = v:sq_length()
    local tick_distance = roots.speed * state.dt
    local tick_distance_sq = tick_distance * tick_distance

    if attack_state == AttackState.ATTACKING then
        local grow_v = nil
        if iter_size(roots.grow_node.neighbors) == 1 then
            local neighbor = first_value(roots.grow_node.neighbors)
            grow_v = Vector(roots.grow_node.x, roots.grow_node.y,
                            (2 * roots.grow_node.x - neighbor.x),
                            (2 * roots.grow_node.y - neighbor.y))
            grow_v:scale_to_length(tick_distance)
        end

        if grow_v ~= nil and (v:dot(grow_v) < 0 or sqln < tick_distance_sq) then
            v = grow_v
            sqln = tick_distance_sq
        elseif sqln < tick_distance_sq and sqln > 0 then
            v:scale_to_length(tick_distance)
            sqln = tick_distance_sq
        end
    end

    if sqln == 0 then
        roots.new_pos_x = NONE
        roots.new_pos_y = NONE
        return
    end


    roots.new_pos_x = roots.grow_node.x + v:direction_x() * roots.speed * state.dt
    roots.new_pos_y = roots.grow_node.y + v:direction_y() * roots.speed * state.dt
    if sqln < tick_distance_sq then
        roots.valid = false
    elseif LEVEL.solid({x = roots.new_pos_x, y = roots.new_pos_y}) then
        roots.valid = false
    else
        roots.valid = true
    end

    if tooltip.timer == nil and not inputs.roots_attack then
        roots.tree_spot = nil_coalesce(TREE_SPOT.find_tree_spot(state.tree_spots, roots.new_pos_x, roots.new_pos_y), NONE)
        if roots.tree_spot ~= nil then
            if roots.selected ~= nil then
                tooltip.timer = state.t
                tooltip.duration = TREE_SPOT.TIME
            end
        else
            roots.terminal = nil_coalesce(TERMINAL.find_terminal(state.terminals, roots.new_pos_x, roots.new_pos_y), NONE)
            if roots.terminal ~= nil and roots.selected ~= nil then
                tooltip.timer = state.t
                tooltip.duration = TERMINAL.TIME
            end
        end
    else
        if roots.tree_spot ~= nil and (roots.tree_spot.node ~= nil or roots.selected == nil or inputs.roots_attack) then
            roots.tree_spot = NONE
            tooltip.timer = NONE
            roots.selected = NONE
            roots.grow_branch = NONE
        end
        if roots.terminal ~= nil and (roots.terminal.node ~= nil or roots.selected == nil or inputs.roots_attack) then
            roots.terminal = NONE
            tooltip.timer = NONE
            roots.selected = NONE
            roots.grow_branch = NONE
        end
    end

    if roots.selected ~= nil and attack_state ~= AttackState.CHARGING then
        if roots.valid then
            if roots.tree_spot ~= nil and roots.tree_spot.node == nil then
                if (state.t - tooltip.timer) > TREE_SPOT.TIME then
                    TREE_SPOT.create_node(roots.tree_spot, roots.selected, state)
                    roots.selected = NONE
                    roots.grow_branch = NONE
                end
            elseif roots.terminal ~= nil and roots.terminal.node == nil then
                if (state.t - tooltip.timer) > TERMINAL.TIME then
                    TERMINAL.create_node(roots.terminal, roots.selected, state)
                    roots.selected = NONE
                    roots.grow_branch = NONE
                end
            else
                local closest = state.nodes:closest(roots.new_pos_x, roots.new_pos_y)
                local threshold = 0.5 * tick_distance_sq
                local connected = NODE.are_connected(roots.selected, closest)
                if connected then
                    threshold = threshold * 0.2
                end
                if attack_state ~= AttackState.ATTACKING and closest ~= nil and closest ~= roots.grow_node and sq_dist(closest.x, closest.y, roots.new_pos_x, roots.new_pos_y) <= threshold then
                    if connected then
                        roots.grow_branch = NONE
                    else
                        if roots.grow_branch == nil then
                            roots.grow_branch = BRANCH.add_branch(state, roots.selected, closest)
                        else
                            BRANCH.extend(roots.grow_branch, closest)
                        end
                        NODE.connect(roots.selected, closest)
                    end
                    roots.selected = closest
                else
                    if roots.grow_branch == nil then
                        roots.grow_branch = nil_coalesce(BRANCH.get_if_tip(state, roots.selected), NONE)
                    end
                    roots.selected, branch = NODE.add_node(roots.new_pos_x, roots.new_pos_y, roots.grow_node, state, NODE_TYPE.NORMAL, roots.grow_branch)
                    if roots.grow_branch == nil then
                        roots.grow_branch = branch
                    end
                end
                if attack_state == AttackState.ATTACKING then
                    roots.grow_node = roots.selected
                end
            end
        end
        if attack_state == AttackState.ATTACKING and
                sq_dist(state.player.pos.x, state.player.pos.y, roots.selected.x, roots.selected.y) < ROOTS.KILL_RADIUS ^ 2 then
            PLAYER.kill(state.player, state.t)
        end
    end
end

function ROOTS.draw(state, inputs, dt)
    local roots = state.roots
    local tooltip = state.tooltip

    if roots.grow_node ~= nil then
        local attack_state = ROOTS.get_attack_state(roots, state.t + dt)
        local color = BRANCH.COLOR
        local attack_indicator = false
        if attack_state == AttackState.CHARGING then
            if ROOTS.do_strike(roots, state.t + dt) then
                attack_indicator = true
            end
        elseif attack_state == AttackState.ATTACKING then
            color = ROOTS.ATTACK_COLOR
        elseif attack_state == AttackState.READY then
            local cd_time = ROOTS.ATTACK_CD
            if ROOTS.do_strike(roots) then
                cd_time = cd_time + ROOTS.strike_time(roots)
            end
            local multiplier = math.min((state.t + dt - roots.t_attack - cd_time) / ROOTS.CD_FLASH_TIME, 1)
            color = {
                ROOTS.CD_FLASH_COLOR[1] + (BRANCH.COLOR[1] - ROOTS.CD_FLASH_COLOR[1]) * multiplier,
                ROOTS.CD_FLASH_COLOR[2] + (BRANCH.COLOR[2] - ROOTS.CD_FLASH_COLOR[2]) * multiplier,
                ROOTS.CD_FLASH_COLOR[3] + (BRANCH.COLOR[3] - ROOTS.CD_FLASH_COLOR[3]) * multiplier,
                ROOTS.CD_FLASH_COLOR[4] + (BRANCH.COLOR[4] - ROOTS.CD_FLASH_COLOR[4]) * multiplier,
            }
        end
        local v = Vector(roots.grow_node.x, roots.grow_node.y,
                         roots.new_pos_x, roots.new_pos_y)
        if attack_indicator then
            local strike_time = ROOTS.strike_time(roots, state.t + dt)
            love.graphics.setColor({0.9, 0, 0, 0.4})
            love.graphics.setLineWidth(2)
            love.graphics.line(
                v.x1,
                v.y1,
                v.x1 + v:direction_x() * strike_time * ROOTS.ATTACK_SPEED,
                v.y2 + v:direction_y() * strike_time * ROOTS.ATTACK_SPEED
            )
        end
        BRANCH.draw_spike(
            v.x1,
            v.y1,
            v:direction_x(),
            v:direction_y(),
            roots.speed * state.dt, color)
    end

    if tooltip.timer ~= nil and roots.selected ~= nil then
        if roots.tree_spot ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({inputs.roots_pos_x, inputs.roots_pos_y + 20,
                                roots.tree_spot.x, roots.tree_spot.y})
            local v = Vector(roots.selected.x, roots.selected.y,
                                 roots.tree_spot.x, roots.tree_spot.y)
            BRANCH.draw_spike(
                roots.selected.x,
                roots.selected.y,
                v:direction_x(),
                v:direction_y(),
                ROOTS.SPEED * state.dt)
        end

        if roots.terminal ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({inputs.roots_pos_x, inputs.roots_pos_y + 20,
                                roots.terminal.x, roots.terminal.y})
            local v = Vector(roots.selected.x, roots.selected.y,
                                 roots.terminal.x, roots.terminal.y)
            BRANCH.draw_spike(
                roots.selected.x,
                roots.selected.y,
                v:direction_x(),
                v:direction_y(),
                ROOTS.SPEED * state.dt)
        end
    end
end

require "states.roots"
require "systems.branch"
require "systems.level"
require "systems.node"
require "systems.terminal"
require "systems.tree_spot"

AttackState = {
    READY = 1,
    CHARGING = 2,
    WINDUP = 3,
    STRIKE = 4,
    CLOUD = 5,
    COOLDOWN = 6,
}

ROOTS = {
    SPEED = 130,
    STRIKE_SPEED = 480,
    STRIKE_TIME_MIN = 0.08,
    STRIKE_TIME_MAX = 0.18,
    STRIKE_MIN_CHARGE_T = 0.15,
    STRIKE_MAX_CHARGE_T = 0.26,
    CLOUD_RADIUS = 12,
    CLOUD_DURATION = 3,
    ATTACK_CD = 4,
    ATTACK_WINDUP_TIME = 0.26,
    ATTACK_INDICATOR_CHARGING_COLOR = {1, 0.8, 0.8, 0.1},
    ATTACK_INDICATOR_WINDUP_COLOR = {0.9, 0, 0, 0.4},
    KILL_RADIUS = 14,
    ATTACK_COLOR = {0.4, 0.08, 0.02, 1},
    CD_FLASH_COLOR = {1, 1, 1, 1},
    CD_FLASH_TIME = 0.2,
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
    return lerp(ROOTS.STRIKE_TIME_MIN, ROOTS.STRIKE_TIME_MAX, k)
end

function ROOTS.get_attack_state(roots, t)
    if roots.t_attack == NEVER then
        return AttackState.CHARGING
    end
    if (t - roots.t_attack) <= ROOTS.ATTACK_WINDUP_TIME then
        return AttackState.WINDUP
    end
    if roots.t_attack_end == NEVER then
        if ROOTS.do_strike(roots) then
            return AttackState.STRIKE
        else
            return AttackState.CLOUD
        end
    end
    if (t - roots.t_attack_end) < ROOTS.ATTACK_CD then
        return AttackState.COOLDOWN
    else
        return AttackState.READY
    end
end

function ROOTS.update(state, inputs)
    local roots = state.roots
    local tooltip = state.tooltip

    local reset_attack_timers = function()
        roots.t_charge = -(ROOTS.ATTACK_CD + ROOTS.STRIKE_TIME_MIN + ROOTS.STRIKE_MIN_CHARGE_T)
        roots.t_attack = roots.t_charge + ROOTS.STRIKE_MIN_CHARGE_T
        roots.t_attack_end = roots.t_attack + ROOTS.STRIKE_MIN_CHARGE_T + ROOTS.ATTACK_WINDUP_TIME
    end

    local cancel_attack = function()
        reset_attack_timers()
        attack_state = AttackState.READY
        roots.speed = ROOTS.SPEED
    end

    local end_attack = function()
        roots.t_attack_end = state.t
        attack_state = AttackState.COOLDOWN
        roots.speed = ROOTS.SPEED
    end

    if roots.t_attack == NEVER and roots.t_charge == NEVER then
        reset_attack_timers()
    end

    local attack_state = ROOTS.get_attack_state(roots, state.t)

    if inputs.roots_grow or attack_state == AttackState.STRIKE or attack_state == AttackState.CLOUD or attack_state == AttackState.CHARGING or attack_state == AttackState.WINDUP then
        if roots.selected == nil and roots.grow_node ~= nil and not NODE.is_dead(state, roots.grow_node) then
            roots.selected = roots.grow_node
        end
    else
        roots.selected = NONE
        roots.grow_branch = NONE
    end

    if roots.selected ~= nil and NODE.is_dead(state, roots.selected) then
        roots.selected = NONE
        roots.grow_branch = NONE

        if attack_state == AttackState.WINDUP or attack_state == AttackState.CHARGING or attack_state == AttackState.CLOUD or attack_state == AttackState.STRIKE then
            roots.grow_node = nil_coalesce(state.nodes:closest(inputs.roots_pos_x, inputs.roots_pos_y), NONE)
            roots.selected = roots.grow_node
            if attack_state == AttackState.WINDUP or attack_state == AttackState.CHARGING then
                cancel_attack()
            end
        end
    end

    if attack_state == AttackState.CHARGING and not inputs.roots_grow then
        roots.attack_cancellable = true
    elseif attack_state == AttackState.READY and roots.attack_cancellable and not inputs.roots_attack then
        roots.attack_cancellable = false
    end

    if inputs.roots_attack and not roots.attack_cancellable then
        if attack_state == AttackState.READY and tooltip.timer == nil then
            roots.t_charge = state.t
            roots.t_attack = NEVER
            roots.t_attack_end = NEVER
            attack_state = AttackState.CHARGING
            roots.attack_cancellable = false
        end
    end

    if roots.selected ~= nil and tooltip.timer == nil then
        roots.grow_node = roots.selected
    else
        if not (attack_state == AttackState.CHARGING or attack_state == AttackState.STRIKE or attack_state == AttackState.CLOUD) then
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
    local grow_node = NODE.from_id(state, roots.grow_node)

    if attack_state == AttackState.CHARGING then
        if not inputs.roots_attack then
            roots.t_attack = state.t
        elseif roots.attack_cancellable and inputs.roots_grow then
            cancel_attack()
        end
    elseif attack_state == AttackState.WINDUP then
        if roots.attack_cancellable and inputs.roots_grow then
            cancel_attack()
        end
    elseif attack_state == AttackState.CLOUD then
        local t_since_start = (state.t - (roots.t_attack + ROOTS.ATTACK_WINDUP_TIME))
        if t_since_start < state.dt then
            PARTICLE.add_cloud(state, grow_node.x, grow_node.y, ROOTS.CLOUD_RADIUS, ROOTS.CLOUD_DURATION - t_since_start)
        elseif t_since_start > ROOTS.CLOUD_DURATION then
            end_attack()
        end
    elseif attack_state == AttackState.STRIKE then
        if (state.t - roots.t_attack) < (ROOTS.ATTACK_WINDUP_TIME + ROOTS.strike_time(roots)) then
            roots.speed = ROOTS.STRIKE_SPEED
        else
            end_attack()
        end
    elseif attack_state == AttackState.CLOUD then
        if (state.t - roots.t_attack) < (ROOTS.ATTACK_WINDUP_TIME + ROOTS.CLOUD_DURATION) then
            if roots.attack_cancellable and inputs.roots_grow then
                end_attack()
            end
        else
            end_attack()
        end
    else
        roots.speed = ROOTS.SPEED
    end
    -- print(get_key(AttackState, attack_state))

    local v = Vector(grow_node.x, grow_node.y,
                     inputs.roots_pos_x, inputs.roots_pos_y)
    local sqln = v:sq_length()
    local tick_distance = roots.speed * state.dt
    local tick_distance_sq = tick_distance * tick_distance

    if attack_state == AttackState.STRIKE and roots.t_attack ~= state.t then
        local grow_v = nil
        if iter_size(grow_node.neighbors) == 1 then
            local neighbor = NODE.from_id(state, first_value(grow_node.neighbors))
            grow_v = Vector(grow_node.x, grow_node.y,
                            (2 * grow_node.x - neighbor.x),
                            (2 * grow_node.y - neighbor.y))
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

    roots.new_pos_x = grow_node.x + v:direction_x() * roots.speed * state.dt
    roots.new_pos_y = grow_node.y + v:direction_y() * roots.speed * state.dt
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
        if roots.tree_spot ~= nil and (roots.tree_spot.node ~= nil or roots.selected == nil or attack_state == AttackState.CLOUD or attack_state == AttackState.CHARGING or attack_state == AttackState.WINDUP or attack_state == AttackState.STRIKE or (attack_state == AttackState.READY and inputs.roots_attack)) then
            roots.tree_spot = NONE
            tooltip.timer = NONE
            roots.selected = NONE
            roots.grow_branch = NONE
        end
        if roots.terminal ~= nil and (roots.terminal.node ~= nil or roots.selected == nil or attack_state == AttackState.CLOUD or attack_state == AttackState.CHARGING or attack_state == AttackState.WINDUP or attack_state == AttackState.STRIKE or (attack_state == AttackState.READY and inputs.roots_attack)) then
            roots.terminal = NONE
            tooltip.timer = NONE
            roots.selected = NONE
            roots.grow_branch = NONE
        end
    end

    if roots.selected ~= nil and attack_state ~= AttackState.CHARGING and attack_state ~= AttackState.WINDUP and attack_state ~= AttackState.CLOUD then
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
                local closest_node = NODE.from_id(state, closest)
                local threshold = 0.5 * tick_distance_sq
                local connected = NODE.are_connected(state, roots.selected, closest)
                if connected then
                    threshold = threshold * 0.2
                end
                if attack_state ~= AttackState.STRIKE and closest ~= nil and closest ~= roots.grow_node and sq_dist(closest_node.x, closest_node.y, roots.new_pos_x, roots.new_pos_y) <= threshold then
                    if connected then
                        roots.grow_branch = NONE
                    else
                        if roots.grow_branch == nil then
                            roots.grow_branch = BRANCH.add_branch(state, roots.selected, closest)
                        else
                            BRANCH.extend(state, roots.grow_branch, closest)
                        end
                        NODE.connect(state, roots.selected, closest)
                    end
                    roots.selected = closest
                else
                    if roots.grow_branch == nil then
                        roots.grow_branch = nil_coalesce(BRANCH.get_if_tip(state, roots.selected), NONE)
                    end

                    local n = math.ceil(roots.speed / ROOTS.SPEED)
                    for i = 1, n do
                        local d = 1 / (n - i + 1)
                        local x = lerp(grow_node.x, roots.new_pos_x, d)
                        local y = lerp(grow_node.y, roots.new_pos_y, d)
                        roots.selected, branch = NODE.add_node(x, y, roots.grow_node, state, NODE_TYPE.NORMAL, roots.grow_branch)

                        if roots.grow_branch == nil then
                            roots.grow_branch = branch
                        end
                        if i < n then
                            roots.grow_node = roots.selected
                        end
                    end
                end
            end
        end
        local selected = NODE.from_id(state, roots.selected)
        if attack_state == AttackState.STRIKE and
                sq_dist(state.player.pos.x, state.player.pos.y, selected.x, selected.y) < ROOTS.KILL_RADIUS ^ 2 then
            PLAYER.kill(state.player, state.t)
        end
    end
end

function ROOTS.draw(state, inputs, dt)
    local roots = state.roots
    local tooltip = state.tooltip

    if roots.grow_node ~= nil then
        local grow_node = NODE.from_id(state, roots.grow_node)

        local attack_state = ROOTS.get_attack_state(roots, state.t + dt)
        local color = BRANCH.COLOR
        local attack_indicator_color
        if attack_state == AttackState.CHARGING then
            attack_indicator_color = ROOTS.ATTACK_INDICATOR_CHARGING_COLOR
        elseif attack_state == AttackState.WINDUP or attack_state == AttackState.STRIKE then
            attack_indicator_color = ROOTS.ATTACK_INDICATOR_WINDUP_COLOR
        elseif attack_state == AttackState.READY then
            local cd_time = ROOTS.ATTACK_CD
            local multiplier = math.min((state.t + dt - roots.t_attack_end - cd_time) / ROOTS.CD_FLASH_TIME, 1)
            color = {
                ROOTS.CD_FLASH_COLOR[1] + (BRANCH.COLOR[1] - ROOTS.CD_FLASH_COLOR[1]) * multiplier,
                ROOTS.CD_FLASH_COLOR[2] + (BRANCH.COLOR[2] - ROOTS.CD_FLASH_COLOR[2]) * multiplier,
                ROOTS.CD_FLASH_COLOR[3] + (BRANCH.COLOR[3] - ROOTS.CD_FLASH_COLOR[3]) * multiplier,
                ROOTS.CD_FLASH_COLOR[4] + (BRANCH.COLOR[4] - ROOTS.CD_FLASH_COLOR[4]) * multiplier,
            }
        end
        local v = Vector(grow_node.x, grow_node.y,
                         roots.new_pos_x, roots.new_pos_y)
        if attack_indicator_color ~= nil then
            love.graphics.setColor(attack_indicator_color)
            local t_attack = roots.t_attack
            if t_attack == NEVER then
                t_attack = state.t + dt
            end
            if ROOTS.do_strike(roots, t_attack) then
                local strike_time = ROOTS.strike_time(roots, t_attack)
                if attack_state == AttackState.STRIKE then
                    -- wind down over strike duration
                    strike_time = math.max(0, strike_time - (state.t + dt - (t_attack + ROOTS.ATTACK_WINDUP_TIME)))
                end
                love.graphics.setLineWidth(2)
                love.graphics.line(
                    v.x1,
                    v.y1,
                    v.x1 + v:direction_x() * strike_time * ROOTS.STRIKE_SPEED,
                    v.y2 + v:direction_y() * strike_time * ROOTS.STRIKE_SPEED
                )
            else
                love.graphics.circle(
                    "fill",
                    grow_node.x,
                    grow_node.y,
                    ROOTS.CLOUD_RADIUS
                )
            end

        end
        BRANCH.draw_spike(
            v.x1,
            v.y1,
            v:direction_x(),
            v:direction_y(),
            roots.speed * state.dt, color)
    end

    if tooltip.timer ~= nil and roots.selected ~= nil then
        local selected = NODE.from_id(state, roots.selected)

        if roots.tree_spot ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({inputs.roots_pos_x, inputs.roots_pos_y + 20,
                                roots.tree_spot.x, roots.tree_spot.y})
            local v = Vector(selected.x, selected.y,
                             roots.tree_spot.x, roots.tree_spot.y)
            BRANCH.draw_spike(
                selected.x,
                selected.y,
                v:direction_x(),
                v:direction_y(),
                ROOTS.SPEED * state.dt)
        end

        if roots.terminal ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({inputs.roots_pos_x, inputs.roots_pos_y + 20,
                                roots.terminal.x, roots.terminal.y})
            local v = Vector(selected.x, selected.y,
                             roots.terminal.x, roots.terminal.y)
            BRANCH.draw_spike(
                selected.x,
                selected.y,
                v:direction_x(),
                v:direction_y(),
                ROOTS.SPEED * state.dt)
        end
    end
end

require "asset_cache"
require "direction"
require "sprite"
require "states.player"
require "systems.level"
require "systems.particle"

PLAYER = {
    -- main config
    sprite_size = 24,
    size = 18,
    respawn_time = 3,
    spawn_pos = {x = 3, y = 3},

    -- movement config
    acceleration_time = 0.2,
    root_slowdown = 0.5,
    base_speed = 100,
    attack_duration = 0.5,

    -- dash config
    dash_speed = 480,
    dash_duration = 0.24,
    dash_end_duration = 0.5,
    dash_end_speed = 0,

    -- attack config
    min_attack_radius = 10,
    max_attack_radius = 20,
    attack_cooldown = 1,
    attack_centre_offset = 8,
    t_max_charge = 0.7,
    attack_duration = 0.53,
    attack_indicator_color = {0.9, 0, 0, 0.4},

    -- powerup config
    coffee_half_life = 15,
    coffee_speedup = 80,
    throw_speed = 200,
    coffee_shake_amount = 0.08,
    coffee_buzz_amount = 0.1,

    -- sprites
    sprite_sets = {
        idle = sprite.make_set("player/", {
            left = "PlayerleftIdle",
            right = "PlayerrightIdle",
            up = "PlayerbackIdle",
            down = "PlayerfrontIdle",
        }),
        walk = sprite.make_set("player/", {
            left = { "Player walk/Leftwalk1", "Player walk/Leftwalk2" },
            right = { "Player walk/Rightwalk1", "Player walk/Rightwalk2" },
            up = { "Player walk/Backwalk1", "Player walk/Backwalk2" },
            down = { "Player walk/Frontwalk1", "Player walk/Frontwalk2" },
        }),
        swing = sprite.make_set("player/", {
            left = "Playerleftswing2",
            right = "Playerrightswing2",
            up = "Playerbackswing2",
            down = "Playerfrontswing2",
        }),
        charge = sprite.make_set("player/", {
            left = "Playerleftswing1",
            right = "Playerrightswing1",
            up = "Playerbackswing1",
            down = "Playerfrontswing1",
        }),
        dead = sprite.make_set("player/", {
            left = "PlayerleftIdle",
            right = "PlayerrightIdle",
            up = "PlayerbackIdle",
            down = "PlayerfrontIdle",
        }),
    },

    sounds = {
        swing = assets:get_sound("woosh"),
        hit = assets:get_sound("wooshsmack"),
        death = assets:get_sound("deathsouth"),
    },
}

DashState = {
    READY = 1,
    DASHING = 2,
    DASH_END = 3,
}

SwingState = {
    READY = 1,
    CHARGING = 2,
    SWINGING = 3,
    THROWING = 4,
}

function PLAYER.update(state, inputs)
    local player = state.player

    if player.time_of_death == NEVER then
        PLAYER.input(state, inputs)
        PLAYER.move(state)
    elseif (state.t - player.time_of_death) >= PLAYER.respawn_time then
        PLAYER.spawn(player)
    end
    if love.math.random() < PLAYER.coffee_buzz_amount * (PLAYER.coffee_amount(player, state.t) - 0.1) then
        PARTICLE.add_buzz(state, random_in_circle(player.pos.x, player.pos.y, PLAYER.size))
    end
end

function PLAYER.draw(state, inputs, dt)
    local player = state.player

    local sprite = PLAYER.sprite(player, state.t + dt)

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    local sx = PLAYER.sprite_size / sprite:getWidth()
    local sy = PLAYER.sprite_size / sprite:getHeight()

    local swing_state = PLAYER.get_swing_state(player, state.t + dt)
    local dash_state = PLAYER.get_dash_state(player, state.t + dt)

    -- draw attack
    if swing_state == SwingState.CHARGING then
        local attack_radius = PLAYER.attack_radius(state.t + dt - player.charge_t0)
        local centre = PLAYER.attack_centre(player)
        love.graphics.setColor(PLAYER.attack_indicator_color)
        love.graphics.circle("fill", centre.x, centre.y, attack_radius)
    elseif swing_state == SwingState.SWINGING then
        local attack_radius = PLAYER.attack_radius(player.swing_t0 - player.charge_t0)
        local centre = PLAYER.attack_centre(player)
        local progress = clamp((state.t + dt - player.swing_t0) / PLAYER.attack_duration, 0, 1)
        love.graphics.setColor(1, 0.8, 0.8, 0.06 * (1 - progress))
        love.graphics.circle("fill", centre.x, centre.y, attack_radius * (1 + progress))
    end

    -- draw player
    local x = player.pos.x + player.vel.x * dt
    local y = player.pos.y + player.vel.y * dt
    local r = 0

    if love.math.random() < PLAYER.coffee_shake_amount * (PLAYER.coffee_amount(player, state.t) - 0.1) then
        if love.math.random() < 0.5 then
            x = x + 1
        else
            x = x - 1
        end
    end
    if love.math.random() < PLAYER.coffee_shake_amount * (PLAYER.coffee_amount(player, state.t) - 0.1) then
        if love.math.random() < 0.5 then
            y = y + 1
        else
            y = y - 1
        end
    end

    if player.time_of_death == NEVER then
        love.graphics.setColor(1, 1, 1, 1)
        if dash_state == DashState.DASHING then
            local shader = assets:get_shader("ui/highlight")
            shader:send("amount", 0.4)
            love.graphics.setShader(shader)
        end
        love.graphics.draw(sprite, round(x), round(y), r, sx, sy, ox, oy)
        love.graphics.setShader()

        if player.has_bomb then
            local bomb = assets:get_image("bomb")
            love.graphics.draw(
                bomb,
                round(x),
                round(y - (sprite:getHeight() + bomb:getHeight()) / 2 - 2),
                0,
                1,
                1,
                bomb:getWidth() / 2,
                bomb:getHeight() / 2
            )
        else
            local attack_state = ROOTS.get_attack_state(state.roots, state.t + dt)
            if attack_state == AttackState.WINDUP or attack_state == AttackState.STRIKE then
                local selected = NODE.from_id(state, state.roots.selected)
                if sq_dist(selected.x, selected.y, player.pos.x, player.pos.y) < 128 ^ 2 then
                    love.graphics.setColor(ROOTS.ATTACK_INDICATOR_WINDUP_COLOR)
                    love.graphics.setFont(font16)
                    love.graphics.print(
                        "!",
                        round(x) - 3,
                        round(y - sprite:getHeight() - 2)
                    )
                end
            end
        end
    else
        local opacity = 1 - math.min(1, (state.t + dt - player.time_of_death) / PLAYER.respawn_time)
        love.graphics.setColor(1, 0.2, 0.2, opacity)
        love.graphics.draw(sprite, x, y, 0, sx, -sy, ox, oy)
    end
end

function PLAYER.sprite(player, t)
    if PLAYER.is_swinging(player, t) then
        return sprite.directional(PLAYER.sprite_sets.swing, player.dir)
    end

    if player.charge_t0 ~= NEVER then
        return sprite.directional(PLAYER.sprite_sets.charge, player.dir)
    end

    if player.speed ~= 0 then
        return sprite.cycling(sprite.directional(PLAYER.sprite_sets.walk, player.dir), 0.5, t)
    end

    return sprite.directional(PLAYER.sprite_sets.idle, player.dir)
end

function PLAYER.is_swinging(player, t)
    return (t - player.swing_t0) < PLAYER.attack_duration
end

function PLAYER.get_swing_state(player, t)
    if player.swing_t0 == NEVER then
        if player.charge_t0 ~= NEVER then
            return SwingState.CHARGING
        else
            return SwingState.READY
        end
    end
    local progress = (t - player.swing_t0)
    if progress > (PLAYER.attack_duration) then
        return SwingState.READY
    elseif player.charge_t0 ~= NEVER then
        return SwingState.SWINGING
    else 
        return SwingState.THROWING
    end
end

function PLAYER.get_dash_state(player, t)
    if player.dash_t0 == NEVER then
        return DashState.READY
    end
    local progress = (t - player.dash_t0)
    if progress > (PLAYER.dash_duration + PLAYER.dash_end_duration) then
        return DashState.READY
    elseif progress > PLAYER.dash_duration then
        return DashState.DASH_END
    else 
        return DashState.DASHING
    end
end

function PLAYER.attack_centre(player)
    local adj = {}
    local y_offset = PLAYER.size / 4
    if player.dir == Direction.UP then
        adj = { x = 0, y = y_offset - PLAYER.attack_centre_offset }
    elseif player.dir == Direction.DOWN then
        adj = { x = 0, y = y_offset + PLAYER.attack_centre_offset }
    elseif player.dir == Direction.LEFT then
        adj = { x = -PLAYER.attack_centre_offset, y = y_offset }
    elseif player.dir == Direction.RIGHT then
        adj = { x = PLAYER.attack_centre_offset, y = y_offset }
    end

    return moved(player.pos, adj)
end

function PLAYER.throw_bomb(state)
    local player = state.player
    local swing_state = PLAYER.get_swing_state(player, state.t)
    if swing_state ~= SwingState.READY then
        return
    end

    player.has_bomb = false
    local speed = player.speed + PLAYER.throw_speed
    PARTICLE.add_bomb(state, player.pos.x, player.pos.y, speed * direction_to_x(player.dir), speed * direction_to_y(player.dir))
    PLAYER.sounds.swing:play()
    player.swing_t0 = state.t
    player.charge_t0 = NEVER
    return
end

function PLAYER.attack_radius(t_charge)
    return lerp(PLAYER.min_attack_radius, PLAYER.max_attack_radius, math.min(t_charge, PLAYER.t_max_charge) / PLAYER.t_max_charge)
end

function PLAYER.attack(state)
    local player = state.player
    local swing_state = PLAYER.get_swing_state(player, state.t)

    if swing_state ~= SwingState.CHARGING then
        return
    end

    PLAYER.sounds.swing:play()
    player.swing_t0 = state.t

    local atk_centre = PLAYER.attack_centre(player)
    local nodes_to_cut = state.nodes:in_radius(atk_centre.x,
                                               atk_centre.y,
                                               PLAYER.attack_radius(state.t - player.charge_t0))

    if #nodes_to_cut > 0 then
        PLAYER.sounds.hit:play()
    end

    for _, node in ipairs(nodes_to_cut) do
        NODE.cut(state, node)
    end
end

function PLAYER.input(state, inputs)
    local player = state.player

    if inputs.player_up then
        if player.started_holding.UP == NEVER then
            player.started_holding.UP = state.t
        end
    else
        player.started_holding.UP = NEVER
    end
    if inputs.player_down then
        if player.started_holding.DOWN == NEVER then
            player.started_holding.DOWN = state.t
        end
    else
        player.started_holding.DOWN = NEVER
    end
    if inputs.player_left then
        if player.started_holding.LEFT == NEVER then
            player.started_holding.LEFT = state.t
        end
    else
        player.started_holding.LEFT = NEVER
    end
    if inputs.player_right then
        if player.started_holding.RIGHT == NEVER then
            player.started_holding.RIGHT = state.t
        end
    else
        player.started_holding.RIGHT = NEVER
    end

    local swing_state = PLAYER.get_swing_state(player, state.t)

    if player.swing_t0 ~= NEVER and swing_state == SwingState.READY then
        player.charge_t0 = NEVER
        player.swing_t0 = NEVER
    end

    local dash_state = PLAYER.get_dash_state(player, state.t)

    if swing_state == SwingState.SWINGING or
       swing_state == SwingState.THROWING or
       dash_state == DashState.DASHING or
       dash_state == DashState.DASH_END then
        return
    end

    if inputs.player_dash and dash_state == DashState.READY then
        player.charge_t0 = NEVER
        player.swing_t0 = NEVER
        player.dash_t0 = state.t
    elseif inputs.player_chop then
        if player.has_bomb then
            PLAYER.throw_bomb(state)
        elseif player.charge_t0 == NEVER then
            player.charge_t0 = state.t
        end
    elseif player.charge_t0 ~= NEVER then
        PLAYER.attack(state)
    end
end

function PLAYER.coffee_amount(player, t)
    if player.coffee_t0 == NEVER then
        return 0
    end
    return clamp(0.5 ^ ((t - player.coffee_t0) / PLAYER.coffee_half_life), 0, 1)
end

function PLAYER.max_speed(player, t)
    if player.coffee_t0 == NEVER then
        return PLAYER.base_speed
    end
    return PLAYER.base_speed + PLAYER.coffee_amount(player, t) * PLAYER.coffee_speedup
end

function PLAYER.get_movement(state)
    local player = state.player
    local dash_state = PLAYER.get_dash_state(player, state.t)

    local most_recent = { dir = player.dir, when = player.started_holding[player.dir] or NEVER }

    if dash_state == DashState.READY then
        for direction, time in pairs(player.started_holding) do
            if time > most_recent.when or (time == most_recent.when and Direction[direction] > most_recent.dir) then
                most_recent = { dir = Direction[direction], when = time }
            end
        end
    end

    if dash_state == DashState.DASHING then
        local progress = clamp((state.t - player.dash_t0) / PLAYER.dash_duration, 0, 1)
        most_recent.speed = lerp(PLAYER.dash_speed, PLAYER.dash_end_speed, progress)
    elseif dash_state == DashState.DASH_END then
        local progress = clamp((state.t - player.dash_t0 + PLAYER.dash_duration) / PLAYER.dash_end_duration, 0, 1)
        most_recent.speed = PLAYER.dash_end_speed * (1 - progress)
    else
        most_recent.speed = PLAYER.max_speed(player, state.t)
        if state.nodes:any_in_radius(player.pos.x, player.pos.y, PLAYER.size / 2) then
            most_recent.speed = most_recent.speed * PLAYER.root_slowdown
        end
        most_recent.speed = most_recent.speed * (0.5 + 0.5 * math.min(1, (state.t - most_recent.when) / PLAYER.acceleration_time))
    end

    return most_recent
end

function PLAYER.velocity(player)
    if player.dir == Direction.UP then
        return { x = 0, y = -player.speed }
    elseif player.dir == Direction.DOWN then
        return { x = 0, y = player.speed }
    elseif player.dir == Direction.LEFT then
        return { x = -player.speed, y = 0 }
    elseif player.dir == Direction.RIGHT then
        return { x = player.speed, y = 0 }
    end
end

function PLAYER.bounds(player, pos)
    if pos == nil then
        pos = player.pos
    end

    local off = PLAYER.size / 2

    return { left   = pos.x - off,
             right  = pos.x + off,
             top    = pos.y - off,
             bottom = pos.y + off }
end

function PLAYER.collision_x(player, dt)
    local delta = {x = player.vel.x * dt, y = 0}
    local curr_bounds = PLAYER.bounds(player)
    local next_bounds = PLAYER.bounds(player, moved(player.pos, delta))

    local adjustment = 0

    -- check player's left edge (right edge of obstacle)
    local curr_left_cell_x, top_cell_y    = LEVEL.cell(curr_bounds.left, next_bounds.top)
    local next_left_cell_x, bottom_cell_y = LEVEL.cell(next_bounds.left, next_bounds.bottom)

    for vert_cell=top_cell_y, bottom_cell_y do
        local vert_y = vert_cell * LEVEL.cell_size()

        if LEVEL.solid({x = next_bounds.left, y = vert_y}) then
            local intersection_x,_ = LEVEL.position_in_cell(next_bounds.left, vert_y)
            adjustment = LEVEL.cell_size() - intersection_x
            break
        end
    end

    -- check player's right edge (left edge of obstacle)
    local curr_right_cell_x = LEVEL.cell_x(curr_bounds.right)
    local next_right_cell_x = LEVEL.cell_x(next_bounds.right)

    for vert_cell=top_cell_y, bottom_cell_y do
        local vert_y = vert_cell * LEVEL.cell_size()

        if LEVEL.solid({x = next_bounds.right, y = vert_y}) then
            local intersection_x,_ = LEVEL.position_in_cell(next_bounds.right, vert_y)
            adjustment = - (intersection_x + 1)  -- +1 puts you just outside the solid cell
            break
        end
    end

    player.vel.x = player.vel.x + (adjustment / dt)
end

function PLAYER.collision_y(player, dt)
    local delta = {x = 0, y = player.vel.y * dt}
    local curr_bounds = PLAYER.bounds(player)
    local next_bounds = PLAYER.bounds(player, moved(player.pos, delta))

    local adjustment = 0

    -- check player's top edge (bottom edge of obstacle)
    local left_cell_x, curr_top_cell_y  = LEVEL.cell(next_bounds.left, curr_bounds.top)
    local right_cell_x, next_top_cell_y = LEVEL.cell(next_bounds.right, next_bounds.top)

    for horiz_cell=left_cell_x, right_cell_x do
        local horiz_x = horiz_cell * LEVEL.cell_size()

        if LEVEL.solid({x = horiz_x, y = next_bounds.top}) then
            local _,intersection_y = LEVEL.position_in_cell(horiz_x, next_bounds.top)
            adjustment = LEVEL.cell_size() - intersection_y
            break
        end
    end

    -- check player's bottom edge (top edge of obstacle)
    local curr_bottom_cell_y = LEVEL.cell_y(curr_bounds.bottom)
    local next_bottom_cell_y = LEVEL.cell_y(next_bounds.bottom)

    for horiz_cell=left_cell_x, right_cell_x do
        local horiz_x = horiz_cell * LEVEL.cell_size()

        if LEVEL.solid({x = horiz_x, y = next_bounds.bottom}) then
            local _,intersection_y = LEVEL.position_in_cell(horiz_x, next_bounds.bottom)
            adjustment = - (intersection_y + 1)  -- +1 puts you just outside the solid cell
            break
        end
    end

    player.vel.y = player.vel.y + (adjustment / dt)
end

function PLAYER.move(state)
    local player = state.player
    player.pos.x = player.pos.x + player.vel.x * state.dt
    player.pos.y = player.pos.y + player.vel.y * state.dt

    local movement = PLAYER.get_movement(state)
    local dash_state = PLAYER.get_dash_state(player, state.t)

    if (movement.when == NEVER and dash_state == DashState.READY) or
            player.charge_t0 ~= NEVER or
            PLAYER.is_swinging(player, state.t) then
        player.speed = 0
        player.vel.x = 0
        player.vel.y = 0
        return
    end

    player.speed = movement.speed
    player.dir = movement.dir

    local vel = PLAYER.velocity(player)
    player.vel.x = vel.x
    player.vel.y = vel.y

    if vel.x ~= 0 then
        PLAYER.collision_x(player, state.dt)
    end
    if vel.y ~= 0 then
        PLAYER.collision_y(player, state.dt)
    end
end

function PLAYER.kill(player, t)
    if player.time_of_death ~= NEVER then
        return
    end
    local dash_state = PLAYER.get_dash_state(player, t)
    if dash_state == DashState.DASHING then
        -- Invulnerable during dash.
        return
    end
    player.time_of_death = t
    player.charge_t0 = NEVER
    player.swing_t0 = NEVER
    player.dash_t0 = NEVER
    PLAYER.sounds.death:play()
end

function PLAYER.spawn(player)
    player.time_of_death = NEVER
    player.pos.x = player.spawn_pos.x
    player.pos.y = player.spawn_pos.y
    player.swing_t0 = NEVER
end

function PLAYER.draw_bounds(player, pos)
    -- draw player's bounding box
    local b = PLAYER.bounds(player, pos)

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", b.left, b.top, player.size, player.size)
    love.graphics.setColor(1, 1, 1, 1)
end

function PLAYER.draw_cells(player, pos)
    -- draw cells occupied by the player
    local b = PLAYER.bounds(player, pos)

    love.graphics.setColor(0, 0, 1, 1)
    for horiz_cell=LEVEL.cell_x(b.left) - 0, LEVEL.cell_x(b.right) + 0 do
        local horiz_x = horiz_cell * LEVEL.cell_size()
        for vert_cell=LEVEL.cell_y(b.top) - 0, LEVEL.cell_y(b.bottom) + 0 do
            local vert_y = vert_cell * LEVEL.cell_size()
            love.graphics.rectangle("line", horiz_x, vert_y, LEVEL.cell_size(), LEVEL.cell_size())
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

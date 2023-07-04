require "utils"
require "asset_cache"
require "direction"
require "sprite"
require "states.player"
require "systems.level"

PLAYER = {
    -- config
    sprite_size = 24,
    size = 18,
    max_speed = 160,
    acceleration_time = 0.2,
    root_speed = 80,
    attack_radius = 12,
    attack_cooldown = 1,
    attack_centre_offset = 8,
    respawn_time = 3,

    spawn_pos = {x = 3, y = 3},
    attack_duration = 0.25,

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
            left = { "Playerleftswing1", "Playerleftswing2" },
            right = { "Playerrightswing1", "Playerrightswing2" },
            up = { "Playerbackswing1", "Playerbackswing2" },
            down = { "Playerfrontswing1", "Playerfrontswing2" },
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

function PLAYER.update(state, inputs)
    local player = state.player

    if player.time_of_death == NEVER then
        PLAYER.input(state, inputs)
        PLAYER.move(state)
    elseif (state.t - player.time_of_death) >= PLAYER.respawn_time then
        PLAYER.spawn(player)
    end
end

function PLAYER.draw(state, inputs, dt)
    local player = state.player

    local sprite = PLAYER.sprite(player, state.t + dt)

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    local sx = PLAYER.sprite_size / sprite:getWidth()
    local sy = PLAYER.sprite_size / sprite:getHeight()

    -- draw player
    local x = round(player.pos.x)
    local y = round(player.pos.y)

    if player.time_of_death == NEVER then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, x, y, 0, sx, sy, ox, oy)
    else
        local opacity = 1 - math.min(1, (state.t + dt - player.time_of_death) / PLAYER.respawn_time)
        love.graphics.setColor(1, 0.2, 0.2, opacity)
        love.graphics.draw(sprite, x, y, 0, sx, -sy, ox, oy)
    end
end

function PLAYER.sprite(player, t)
    if PLAYER.is_swinging(player, t) then
        return sprite.sequence(
            sprite.directional(PLAYER.sprite_sets.swing, player.dir),
            PLAYER.attack_duration,
            t - player.time_of_prev_attack)
    end

    if player.speed ~= 0 then
        return sprite.cycling(sprite.directional(PLAYER.sprite_sets.walk, player.dir), 0.5, t)
    end

    return sprite.directional(PLAYER.sprite_sets.idle, player.dir)
end

function PLAYER.is_swinging(player, t)
    return (t - player.time_of_prev_attack) < PLAYER.attack_duration
end

function PLAYER.attack_centre(player)
    local adj = {}
    if player.dir == Direction.UP then
        adj = { x = 0, y = -PLAYER.attack_centre_offset }
    elseif player.dir == Direction.DOWN then
        adj = { x = 0, y = PLAYER.attack_centre_offset }
    elseif player.dir == Direction.LEFT then
        adj = { x = -PLAYER.attack_centre_offset, y = 0 }
    elseif player.dir == Direction.RIGHT then
        adj = { x = PLAYER.attack_centre_offset, y = 0 }
    end

    return moved(player.pos, adj)
end

function PLAYER.attack(state)
    local player = state.player

    if PLAYER.is_swinging(player, state.t) then
        return
    end

    PLAYER.sounds.swing:play()

    player.time_of_prev_attack = state.t

    local atk_centre = PLAYER.attack_centre(player)
    local nodes_to_cut = NODE.get_within_radius(state, atk_centre.x,
                                                atk_centre.y,
                                                PLAYER.attack_radius)

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

    if inputs.player_chop then
        PLAYER.attack(state)
    end
end

function PLAYER.get_movement(state)
    local player = state.player

    local most_recent = { dir = Direction.UP, when = NEVER }

    for direction, time in pairs(player.started_holding) do
        if time > most_recent.when then
            most_recent = { dir = Direction[direction], when = time }
        end
    end

    most_recent.speed = PLAYER.max_speed
    if #(NODE.get_within_radius(state, player.pos.x, player.pos.y, PLAYER.size / 2)) > 0 then
        most_recent.speed = PLAYER.root_speed
    end
    most_recent.speed = most_recent.speed * (0.5 + 0.5 * math.min(1, (state.t - most_recent.when) / PLAYER.acceleration_time))


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

function PLAYER.collision_x(player)
    local vel = { x = PLAYER.velocity(player).x, y = 0 }
    local next_pos = moved(player.pos, vel)

    local curr_bounds = PLAYER.bounds(player)
    local next_bounds = PLAYER.bounds(player, next_pos)

    local vel_x_adjustment = 0

    -- check player's left edge (right edge of obstacle)
    local curr_left_cell_x, top_cell_y    = LEVEL.cell(curr_bounds.left, next_bounds.top)
    local next_left_cell_x, bottom_cell_y = LEVEL.cell(next_bounds.left, next_bounds.bottom)

    for vert_cell=top_cell_y, bottom_cell_y do
        local vert_y = vert_cell * LEVEL.cell_size()

        if LEVEL.solid({x = next_bounds.left, y = vert_y}) then
            local intersection_x,_ = LEVEL.position_in_cell(next_bounds.left, vert_y)
            vel_x_adjustment = LEVEL.cell_size() - intersection_x
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
            vel_x_adjustment = - (intersection_x + 1)  -- +1 puts you just outside the solid cell
            break
        end
    end

    -- return x velocity adjustment
    return vel_x_adjustment
end

function PLAYER.collision_y(player)
    local vel = { x = 0, y = PLAYER.velocity(player).y }
    local next_pos = moved(player.pos, vel)

    local curr_bounds = PLAYER.bounds(player)
    local next_bounds = PLAYER.bounds(player, next_pos)

    local vel_y_adjustment = 0

    -- check player's top edge (bottom edge of obstacle)
    local left_cell_x, curr_top_cell_y  = LEVEL.cell(next_bounds.left, curr_bounds.top)
    local right_cell_x, next_top_cell_y = LEVEL.cell(next_bounds.right, next_bounds.top)

    for horiz_cell=left_cell_x, right_cell_x do
        local horiz_x = horiz_cell * LEVEL.cell_size()

        if LEVEL.solid({x = horiz_x, y = next_bounds.top}) then
            local _,intersection_y = LEVEL.position_in_cell(horiz_x, next_bounds.top)
            vel_y_adjustment = LEVEL.cell_size() - intersection_y
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
            vel_y_adjustment = - (intersection_y + 1)  -- +1 puts you just outside the solid cell
            break
        end
    end

    -- return y velocity adjustment
    return vel_y_adjustment
end

function PLAYER.move(state)
    local player = state.player

    local movement = PLAYER.get_movement(state)
    if movement.when == NEVER or PLAYER.is_swinging(player, state.t) then
        player.speed = 0
        return
    end

    player.speed = movement.speed * state.dt
    player.dir = movement.dir

    local vel = PLAYER.velocity(player)
    if vel.x ~= 0 then
        vel.x = vel.x + PLAYER.collision_x(player)
    end
    if vel.y ~= 0 then
        vel.y = vel.y + PLAYER.collision_y(player)
    end
    player.pos = moved(player.pos, {x = vel.x, y = vel.y})
end

function PLAYER.kill(player, t)
    player.time_of_death = t
    player.sounds.death:play()
end

function PLAYER.spawn(player)
    player.time_of_death = NEVER
    player.pos = shallowcopy(player.spawn_pos)
    player.time_of_prev_attack = -PLAYER.attack_cooldown
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

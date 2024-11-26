require "systems.level"

POWERUPS = {
    COOLDOWN = 40,
    PICKUP_RADIUS = 15,
    COFFEE_SPEEDUP = 1.265,

    FAR_POS = {x = 22, y = 3},
    NEAR_POS = {x = 3, y = 19}
}

function POWERUPS.update(state, inputs)
    local powerups = state.powerups
    local player = state.player

    if POWERUPS.near_just_spawned(state.t, state) and powerups.near_type == "coffee" then
        powerups.coffee_spawned = powerups.coffee_spawned + 1
    end
    if POWERUPS.far_just_spawned(state.t, state) and powerups.far_type == "coffee" then
        powerups.coffee_spawned = powerups.coffee_spawned + 1
    end

    if POWERUPS.near_ready(state.t, powerups) and sq_dist(
            player.pos.x,
            player.pos.y,
            (POWERUPS.NEAR_POS.x + 0.5) * LEVEL.cell_size(),
            (POWERUPS.NEAR_POS.y + 0.5) * LEVEL.cell_size()) <= (POWERUPS.PICKUP_RADIUS * POWERUPS.PICKUP_RADIUS) then
        if powerups.near_type == "coffee" then
            player.max_speed = player.max_speed * 1.265
            powerups.t_near_taken = state.t

            -- Special case for the first coffee
            powerups.near_type = "bomb"
            powerups.t_near_taken = powerups.t_near_taken - POWERUPS.COOLDOWN / 2
        elseif powerups.near_type == "bomb" and not player.has_bomb then
            player.has_bomb = true
            powerups.t_near_taken = state.t
        end
    end
    if POWERUPS.far_ready(state.t, powerups) and sq_dist(
            player.pos.x,
            player.pos.y,
            (POWERUPS.FAR_POS.x + 0.5) * LEVEL.cell_size(),
            (POWERUPS.FAR_POS.y + 0.5) * LEVEL.cell_size()) <= (POWERUPS.PICKUP_RADIUS * POWERUPS.PICKUP_RADIUS) then
        if powerups.far_type == "coffee" then
            player.max_speed = player.max_speed * 1.265
            powerups.t_far_taken = state.t
            if powerups.coffee_spawned >= 4 then
                powerups.far_type = "bomb"
            end
        elseif powerups.far_type == "bomb" and not player.has_bomb then
            player.has_bomb = true
            powerups.t_far_taken = state.t
        end
    end
end

function POWERUPS.draw(state, inputs, dt)
    local powerups = state.powerups

    if POWERUPS.near_ready(state.t + dt, powerups) then
        local image = assets:get_image(powerups.near_type)
        love.graphics.draw(
            image,
            math.floor((POWERUPS.NEAR_POS.x + 0.5) * LEVEL.cell_size() - image:getWidth() / 2),
            math.floor((POWERUPS.NEAR_POS.y + 0.5) * LEVEL.cell_size() - image:getHeight() / 2)
        )
    end
    if POWERUPS.far_ready(state.t + dt, powerups) then
        local image = assets:get_image(powerups.far_type)
        love.graphics.draw(
            image,
            math.floor((POWERUPS.FAR_POS.x + 0.5) * LEVEL.cell_size() - image:getWidth() / 2),
            math.floor((POWERUPS.FAR_POS.y + 0.5) * LEVEL.cell_size() - image:getHeight() / 2)
        )
    end
end

function POWERUPS.near_ready(t, powerups)
    return (t - powerups.t_near_taken) >= POWERUPS.COOLDOWN
end

function POWERUPS.far_ready(t, powerups)
    return (t - powerups.t_far_taken) >= POWERUPS.COOLDOWN
end

function POWERUPS.near_just_spawned(t, state)
    local d = t - state.powerups.t_near_taken - POWERUPS.COOLDOWN
    return d >= 0 and d < state.dt 
end

function POWERUPS.far_just_spawned(t, state)
    local d = t - state.powerups.t_far_taken - POWERUPS.COOLDOWN
    return d >= 0 and d < state.dt 
end

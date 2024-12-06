require "systems.level"

POWERUPS = {
    COOLDOWN = 6,
    PICKUP_RADIUS = 15,

    FAR_POS = {x = 22, y = 3},
    NEAR_POS = {x = 3, y = 19}
}

function POWERUPS.update(state, inputs)
    local powerups = state.powerups
    local player = state.player

    if POWERUPS.near_ready(state.t, powerups) and sq_dist(
            player.pos.x,
            player.pos.y,
            (POWERUPS.NEAR_POS.x + 0.5) * LEVEL.cell_size(),
            (POWERUPS.NEAR_POS.y + 0.5) * LEVEL.cell_size()) <= (POWERUPS.PICKUP_RADIUS * POWERUPS.PICKUP_RADIUS) then
        if powerups.near_type == "coffee" then
            player.coffee_t0 = state.t
        elseif powerups.near_type == "bomb" and not player.has_bomb then
            player.has_bomb = true
        end
        powerups.t_near_taken = state.t
    end
    if POWERUPS.far_ready(state.t, powerups) and sq_dist(
            player.pos.x,
            player.pos.y,
            (POWERUPS.FAR_POS.x + 0.5) * LEVEL.cell_size(),
            (POWERUPS.FAR_POS.y + 0.5) * LEVEL.cell_size()) <= (POWERUPS.PICKUP_RADIUS * POWERUPS.PICKUP_RADIUS) then
        if powerups.far_type == "coffee" then
            player.coffee_t0 = state.t
        elseif powerups.far_type == "bomb" and not player.has_bomb then
            player.has_bomb = true
        end
        powerups.t_far_taken = state.t
    end
end

function POWERUPS.draw(state, inputs, dt)
    local powerups = state.powerups

    if POWERUPS.near_ready(state.t + dt, powerups) then
        local image = assets:get_image(powerups.near_type)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.draw(
            image,
            math.floor((POWERUPS.NEAR_POS.x + 0.5) * LEVEL.cell_size() - image:getWidth() / 2),
            math.floor((POWERUPS.NEAR_POS.y + 0.5) * LEVEL.cell_size() - image:getHeight() / 2)
        )
    end
    if POWERUPS.far_ready(state.t + dt, powerups) then
        local image = assets:get_image(powerups.far_type)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.draw(
            image,
            math.floor((POWERUPS.FAR_POS.x + 0.5) * LEVEL.cell_size() - image:getWidth() / 2),
            math.floor((POWERUPS.FAR_POS.y + 0.5) * LEVEL.cell_size() - image:getHeight() / 2)
        )
    end
end

function POWERUPS.near_ready(t, powerups)
    if powerups.near_type == nil then
        return false
    end
    return (t - powerups.t_near_taken) >= POWERUPS.COOLDOWN
end

function POWERUPS.far_ready(t, powerups)
    if powerups.far_type == nil then
        return false
    end
    return (t - powerups.t_far_taken) >= POWERUPS.COOLDOWN
end

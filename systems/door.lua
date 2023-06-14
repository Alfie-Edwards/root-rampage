require "utils"
require "sprite"

DOOR = {
    SPRITE = sprite.make("VaultDoor.png"),
    ANIM_TIME = 2,
    ORIGIN_X = 17.5,
    ORIGIN_Y = 45.5,
    WIDTH = 24,
    HEIGHT = 48,
    TOOLTIP_OPEN = "< Escape",
    TOOLTIP_CLOSED = "Locked",
    POS = {x = 2, y = 12},
}

function DOOR.draw(state, inputs, dt)
    local door = state.door

    local anim = 1
    if door.t_anim ~= NEVER then
        anim = math.min(1, (state.t + dt - door.t_anim) / DOOR.ANIM_TIME)
    end
    if not door.is_open then
        anim = 1 - anim
    end
    local angle = math.pi / 2 * anim

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(DOOR.SPRITE, door.x - DOOR.ORIGIN_X, door.y + DOOR.ORIGIN_Y, angle, 1, 1, DOOR.ORIGIN_X, DOOR.ORIGIN_Y)
end

function DOOR.get_center(door)
    return {x = door.x - DOOR.WIDTH / 2,
            y = door.y + DOOR.HEIGHT / 2}
end

function DOOR.open(door, t)
    if not door.is_open then
        door.t_anim = t
        door.is_open = true
    end
end

function DOOR.close(door, t)
    if door.is_open then
        door.t_anim = t
        door.is_open = false
    end
end

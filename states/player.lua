require "utils"
require "engine.state"

PlayerState = {}
setup_class("PlayerState", State)

function PlayerState.new(cell_size, pos)
    assert(cell_size ~= nil)

    pos = shallowcopy(pos or PLAYER.spawn_pos)
    pos.x = pos.x * cell_size
    pos.y = pos.y * cell_size

    local obj = State.new({
        -- main state
        spawn_pos = pos,
        pos = pos,
        speed = 0,
        dir = Direction.DOWN,
        attack_centre = NONE,

        -- other bits of state
        started_holding = {
            LEFT = 0,
            RIGHT = 0,
            UP = 0,
            DOWN = 0,
        },

        time_of_prev_attack = NEVER,
        time_of_death = NEVER,
    })
    setup_instance(obj, PlayerState)

    return obj
end

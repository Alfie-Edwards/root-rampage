require "utils"
require "engine.state"

INPUT_UNDEFINED = {}

Inputs = {
    UNDEFINED = {},
    ALL_UNDEFINED = {
        player_up = INPUT_UNDEFINED,
        player_down = INPUT_UNDEFINED,
        player_left = INPUT_UNDEFINED,
        player_right = INPUT_UNDEFINED,
        player_chop = INPUT_UNDEFINED,
        roots_grow = INPUT_UNDEFINED,
        roots_attack = INPUT_UNDEFINED,
        roots_pos_x = INPUT_UNDEFINED,
        roots_pos_y = INPUT_UNDEFINED,
    },
    DEFAULTS = {
        player_up = false,
        player_down = false,
        player_left = false,
        player_right = false,
        player_chop = false,
        roots_grow = false,
        roots_attack = false,
        roots_pos_x = 0,
        roots_pos_y = 0,
    },
}
setup_class(Inputs, State)

function Inputs.new_undefined()
    local obj = magic_new(Inputs.UNDEFINED)

    return obj
end

function Inputs.new_defaults()
    local obj = magic_new(Inputs.DEFAULTS)

    return obj
end

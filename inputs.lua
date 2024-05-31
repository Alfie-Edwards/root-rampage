
INPUT_UNDEFINED = {}

Inputs = {
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
setup_class(Inputs, FixedPropertyTable)

function Inputs.new_undefined()
    return Inputs(Inputs.ALL_UNDEFINED)
end

function Inputs.new_defaults()
    return Inputs(Inputs.DEFAULTS)
end

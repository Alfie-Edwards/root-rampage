
RootsState = {}
setup_class(RootsState, State)

function RootsState.new()
    local obj = magic_new({
        t_attack = NEVER,
        selected = NONE,
        grow_node = NONE,
        new_pos_x = NONE,
        new_pos_y = NONE,
        valid = false,
        speed = ROOTS.SPEED,
        tree_spot = NONE,
        terminal = NONE,
    })

    return obj
end

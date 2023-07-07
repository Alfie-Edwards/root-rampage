
NodeState = {}
setup_class(NodeState, State)

function NodeState.new(x, y, parent)
    local obj = magic_new({
        x = x,
        y = y,
        children = {},
        is_tree = false,
        is_terminal = is_terminal,
        t_dead = NEVER,
        is_dead = false,
        parent = parent,
    })

    return obj
end

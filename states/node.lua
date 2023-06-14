require "utils"
require "engine.state"

NodeState = {}
setup_class("NodeState", State)

function NodeState.new(x, y, parent)
    local obj = State.new({
        x = x,
        y = y,
        children = {},
        is_tree = false,
        is_terminal = is_terminal,
        t_dead = NEVER,
        is_dead = false,
        parent = parent,
    })
    setup_instance(obj, NodeState)

    return obj
end

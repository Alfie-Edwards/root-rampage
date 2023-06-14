require "utils"
require "engine.state"

TreeSpotState = {}
setup_class("TreeSpotState", State)

function TreeSpotState.new(x, y)
    assert(x ~= nil)
    assert(y ~= nil)

    local obj = State.new({
        x = x,
        y = y,
        node = NONE,
        t_grown = NEVER,
        t_cut = NEVER,
    })
    setup_instance(obj, TreeSpotState)

    return obj
end

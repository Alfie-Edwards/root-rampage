require "utils"
require "engine.state"

TreeSpotState = {}
setup_class(TreeSpotState, State)

function TreeSpotState.new(x, y)
    assert(x ~= nil)
    assert(y ~= nil)

    local obj = magic_new({
        x = x,
        y = y,
        node = NONE,
        t_grown = NEVER,
        t_cut = NEVER,
    })

    return obj
end

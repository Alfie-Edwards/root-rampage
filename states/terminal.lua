require "utils"
require "engine.state"

TerminalState = {}
setup_class("TerminalState", State)

function TerminalState.new(x, y)
    assert(x ~= nil)
    assert(y ~= nil)

    local obj = State.new({
        x = x,
        y = y,
        node = NONE,
        t_hacked = NEVER,
        t_cut = NEVER,
    })
    setup_instance(obj, TerminalState)

    return obj
end

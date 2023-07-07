
TerminalState = {}
setup_class(TerminalState, State)

function TerminalState.new(x, y)
    assert(x ~= nil)
    assert(y ~= nil)

    local obj = magic_new({
        x = x,
        y = y,
        node = NONE,
        t_hacked = NEVER,
        t_cut = NEVER,
    })

    return obj
end

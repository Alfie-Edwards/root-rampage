
TerminalState = {}
setup_class(TerminalState, FixedPropertyTable)

function TerminalState:__init(x, y)
    assert(x ~= nil)
    assert(y ~= nil)

    super().__init(self, {
        x = x,
        y = y,
        node = NONE,
        t_hacked = NEVER,
        t_cut = NEVER,
    })
end


TreeSpotState = {}
setup_class(TreeSpotState, FixedPropertyTable)

function TreeSpotState:__init(x, y)
    assert(x ~= nil)
    assert(y ~= nil)

    super().__init(self, {
        x = x,
        y = y,
        node = NONE,
        t_grown = NEVER,
        t_cut = NEVER,
    })
end

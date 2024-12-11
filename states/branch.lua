
BranchState = {}
setup_class(BranchState, FixedPropertyTable)

function BranchState:__init(id)
    assert(id ~= nil)
    super().__init(self, {
        length = 0,
        points = PropertyTable(),
        node_list = PropertyTable(),
        t_dead = NEVER,
        id = id,
        -- color = hsva(love.math.random(), 1, 1, 1),
    })
end


BranchState = {}
setup_class(BranchState, FixedPropertyTable)

function BranchState:__init()
    super().__init(self, {
        length = 0,
        points = {},
        node_list = PropertyTable(),
        t_dead = NEVER,
        -- color = hsva(love.math.random(), 1, 1, 1),
    })
end

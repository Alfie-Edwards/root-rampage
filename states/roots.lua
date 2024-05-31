
RootsState = {}
setup_class(RootsState, FixedPropertyTable)

function RootsState:__init()
    super().__init(self, {
        t_attack = NEVER,
        selected = NONE,
        grow_node = NONE,
        new_pos_x = NONE,
        new_pos_y = NONE,
        valid = false,
        speed = ROOTS.SPEED,
        tree_spot = NONE,
        terminal = NONE,
    })
end

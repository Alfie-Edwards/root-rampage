
RootsState = {}
setup_class(RootsState, FixedPropertyTable)

function RootsState:__init()
    super().__init(self, {
        t_charge = NEVER,
        t_attack = NEVER,
        selected = NONE,
        grow_node = NONE,
        grow_branch = NONE,
        new_pos_x = NONE,
        new_pos_y = NONE,
        valid = false,
        speed = ROOTS.SPEED,
        tree_spot = NONE,
        terminal = NONE,
    })
end

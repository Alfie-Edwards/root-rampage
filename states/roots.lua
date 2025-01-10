
RootsState = {}
setup_class(RootsState, FixedPropertyTable)

AttackType = {
    STRIKE = 1,
    CLOUD = 2,
    NONE = 3,
}

function RootsState:__init()
    super().__init(self, {
        t_charge = NEVER,
        t_attack = NEVER,
        t_attack_end = NEVER,
        attack_type = AttackType.NONE,
        attack_cancellable = false,
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

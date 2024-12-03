
PlayerState = {}
setup_class(PlayerState, FixedPropertyTable)

function PlayerState:__init(cell_size, pos)
    assert(cell_size ~= nil)

    pos = shallow_copy(pos or PLAYER.spawn_pos)
    pos.x = pos.x * cell_size
    pos.y = pos.y * cell_size

    super().__init(self, {
        -- main state
        spawn_pos = shallow_copy(pos),
        pos = shallow_copy(pos),
        speed = 0,
        coffee_t0 = NEVER,
        has_bomb = false,
        dir = Direction.DOWN,
        vel = {x = 0, y = 0},
        attack_centre = NONE,
        charge_t0 = NEVER,
        swing_t0 = NEVER,
        dash_t0 = NEVER,

        -- other bits of state
        started_holding = {
            LEFT = 0,
            RIGHT = 0,
            UP = 0,
            DOWN = 0,
        },

        time_of_death = NEVER,
    })
end

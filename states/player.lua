
PlayerState = {}
setup_class(PlayerState, FixedPropertyTable)

function PlayerState:__init(cell_size, pos)
    assert(cell_size ~= nil)

    pos = shallow_copy(pos or PLAYER.spawn_pos)
    pos.x = pos.x * cell_size
    pos.y = pos.y * cell_size

    super().__init(self, {
        -- main state
        spawn_pos = pos,
        pos = pos,
        speed = 0,
        dir = Direction.DOWN,
        attack_centre = NONE,

        -- other bits of state
        started_holding = {
            LEFT = 0,
            RIGHT = 0,
            UP = 0,
            DOWN = 0,
        },

        time_of_prev_attack = NEVER,
        time_of_death = NEVER,
    })
end

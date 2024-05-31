require "systems.door"

DoorState = {}
setup_class(DoorState, FixedPropertyTable)

function DoorState:__init(cell_size, t, pos)
    assert(cell_size ~= nil)

    pos = shallow_copy(pos or DOOR.POS)

    super().__init(self, {
        x = pos.x * cell_size,
        y = pos.y * cell_size,
        is_open = true,
        t_anim = NEVER,
    })

    DOOR.close(self, t)
end

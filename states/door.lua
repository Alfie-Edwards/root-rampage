require "utils"
require "engine.state"
require "systems.door"

DoorState = {}
setup_class("DoorState", State)

function DoorState.new(cell_size, t, pos)
    assert(cell_size ~= nil)

    pos = shallowcopy(pos or DOOR.POS)

    local obj = State.new({
        x = pos.x * cell_size,
        y = pos.y * cell_size,
        is_open = true,
        t_anim = NEVER,
    })
    setup_instance(obj, DoorState)

    DOOR.close(obj, t)

    return obj
end

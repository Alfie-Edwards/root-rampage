require "utils"
require "engine.state"

HackingState = {}
setup_class("HackingState", State)

function HackingState.new()
    local obj = State.new({
        progress = 0,
    })
    setup_instance(obj, HackingState)

    return obj
end

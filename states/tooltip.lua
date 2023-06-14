require "utils"
require "engine.state"

TooltipState = {}
setup_class("TooltipState", State)

function TooltipState.new()
    local obj = State.new({
        timer = NONE,
        duration = 1,
        message = NONE,
    })
    setup_instance(obj, TooltipState)

    return obj
end

require "utils"
require "engine.state"

TooltipState = {}
setup_class(TooltipState, State)

function TooltipState.new()
    local obj = magic_new({
        timer = NONE,
        duration = 1,
        message = NONE,
    })

    return obj
end

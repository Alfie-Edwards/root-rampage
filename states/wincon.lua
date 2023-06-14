require "utils"
require "engine.state"

WinconState = {}
setup_class("WinconState", State)

function WinconState.new()
    local obj = State.new({
        game_over = false,
        end_screen = NONE,
    })
    setup_instance(obj, WinconState)

    return obj
end

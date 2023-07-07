
WinconState = {}
setup_class(WinconState, State)

function WinconState.new()
    local obj = magic_new({
        game_over = false,
        end_screen = NONE,
    })

    return obj
end


HackingState = {}
setup_class(HackingState, State)

function HackingState.new()
    local obj = magic_new({
        progress = 0,
    })

    return obj
end

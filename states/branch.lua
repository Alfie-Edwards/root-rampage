
BranchState = {}
setup_class(BranchState, State)

function BranchState.new(base, child_index)
    assert(base ~= nil)
    assert(child_index ~= nil)

    local obj = magic_new({
        base = base,
        child_index = child_index,
        tip = base,
        length = 1,
        points = {base.x, base.y},
    })

    return obj
end


BranchState = {}
setup_class(BranchState, FixedPropertyTable)

function BranchState:__init(base, child_index)
    assert(base ~= nil)
    assert(child_index ~= nil)

    super().__init(self, {
        base = base,
        child_index = child_index,
        tip = base,
        length = 1,
        points = {base.x, base.y},
    })
end


NodeState = {}

NODE_TYPE = {
    NORMAL = 1,
    TERMINAL = 2,
    TREE = 3,
}

setup_class(NodeState, FixedPropertyTable)

function NodeState:__init(x, y, id, type)
    assert(x ~= nil)
    assert(y ~= nil)

    super().__init(self, {
        x = x,
        y = y,
        neighbors = PropertyTable(),
        is_tree = (type == NODE_TYPE.TREE),
        is_terminal = (type == NODE_TYPE.TERMINAL),
        branch_map = PropertyTable(),
        id = id,
    })
end

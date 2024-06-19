require "states.node"

NODE = {}

function NODE.add_node(x, y, parent, state, type)
    local node = NodeState(x, y, parent, type)
    state.nodes:add(node, x, y)
    state.newest_node = node

    if parent == nil then
        BRANCH.add_branch(state, node, 1)
    else
        NODE.add_child(parent, node)
        if #parent.children > 1 then
            BRANCH.add_branch(state, parent, #parent.children)
        end
    end

    return node
end

function NODE.remove_node(state, node)
    state.nodes:remove(node)
end

function NODE.add_child(parent, child)
    table.insert(parent.children, child)
    child.parent = parent
end

function NODE.remove_child(parent, child)
    assert(child.parent == parent)

    local key = get_key(parent.children, child)
    parent.children[key] = nil
    child.parent = nil
end

function NODE.find_root_node(node)
    local root = node
    while root.parent ~= nil do
        root = root.parent
    end
    return root
end

function NODE.do_to_subtree(node, func)
    func(node)
    for _, child in pairs(node.children) do
        NODE.do_to_subtree(child, func)
    end
end

function NODE.kill_subtree_if_no_trees(node, state)
    local function any_trees(node)
        if node.is_tree then
            return true
        else
            for _,child in pairs(node.children) do
                if any_trees(child) then
                    return true
                end
            end
            return false
        end
    end

    if not any_trees(node) then
        NODE.do_to_subtree(node,
            function(node)
                NODE.kill(node, state)
            end
        )
    end
end

function NODE.cut(state, node)
    -- Cache children and parent.
    local children = shallow_copy(node.children)
    local parent = node.parent

    -- Update all branches starting at this node.
    for _, branch in ipairs(BRANCH.get_branches(state, node)) do
        BRANCH.trim_start(state, branch)
    end

    -- Start a new branch after this node.
    if parent ~= nil then
        local branch = BRANCH.get_main_branch(state, node)
        BRANCH.trim_end_to(branch, parent)
        if #node.children > 0 then
            BRANCH.add_branch(state, node.children[1], 1)
        end
    end

    -- Disconnect node.
    for _, child in pairs(children) do
        NODE.remove_child(node, child)
    end
    if parent ~= nil then
        NODE.remove_child(parent, node)
    end

    -- Kill check on parent graph.
    if parent ~= nil then
        local parent_graph_root = NODE.find_root_node(parent)
        NODE.kill_subtree_if_no_trees(parent_graph_root, state)
    end

    -- Kill check on child graphs.
    for _, child in pairs(children) do
        NODE.kill_subtree_if_no_trees(child, state)
    end

    NODE.kill(node, state)

    -- Create branch containing just this node.
    BRANCH.add_branch(state, node, 1)
end

function NODE.cull(state, node)
    -- NODE.remove_node(state, node)
end

function NODE.kill(node, state)
    NODE.remove_node(state, node)
    node.is_dead = true
    node.t_dead = state.t
end

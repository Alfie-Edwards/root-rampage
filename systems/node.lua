require "states.node"

NODE = {}

function NODE.add_node(x, y, parent, state, type, branch)
    local node = NodeState(x, y, type)
    if parent ~= nil then
        NODE.connect(node, parent)
    end
    state.nodes:add(node, x, y)
    state.newest_node = node

    if parent == nil then
        branch = BRANCH.add_branch(state, node)
    elseif branch == nil then
        branch = BRANCH.add_branch(state, parent, node)
    else
        BRANCH.extend(branch, node)
    end

    return node, branch
end

function NODE.connect(a, b)
    PropertyTable.append(a.neighbors, b)
    PropertyTable.append(b.neighbors, a)
end

function NODE.disconnect(a, b)
    PropertyTable.remove_value(a.neighbors, b)
    PropertyTable.remove_value(b.neighbors, a)
end

function NODE.are_connected(a, b)
    return value_in(a, b.neighbors, pairs)
end

function NODE.remove_node(state, node)
    state.nodes:remove(node)
end

function NODE.is_dead(state, node)
    return not state.nodes:contains(node)
end

function NODE.do_to_subtree(node, func, seen)
    seen = nil_coalesce(seen, {})
    if seen[node] then
        return
    end
    func(node)
    seen[node] = true
    for _, neighbor in pairs(node.neighbors) do
        if not seen[neighbor] then
            NODE.do_to_subtree(neighbor, func, seen)
        end
    end
end

function NODE.kill_subtree_if_no_trees(state, node, cache)
    cache = nil_coalesce(cache, {})

    local function any_trees(node)
        if cache[node] ~= nil then
            return cache[node]
        else
            cache[node] = false
        end
        if node.is_tree then
            return true
        else
            for _, neighbor in pairs(node.neighbors) do
                if any_trees(neighbor) then
                    cache[node] = true
                    return true
                end
            end
            return false
        end
    end

    if not any_trees(node) then
        NODE.do_to_subtree(node,
            function(node)
                NODE.remove_node(state, node)
            end
        )
    end
end

function NODE.cut(state, node)
    if NODE.is_dead(state, node) then
        return
    end

    -- Cache neighbors.
    local neighbors = shallow_copy(node.neighbors)
    for _, neighbor in pairs(neighbors) do
        NODE.disconnect(node, neighbor)
    end

    local branch_map = shallow_copy(node.branch_map)
    for branch_id, indices in pairs(branch_map) do
        table.sort(indices)
        for i = #indices, 1, -1 do
            BRANCH.cut(state, state.branches[branch_id], indices[i])
        end
    end

    local cache = {}
    for _, neighbor in pairs(neighbors) do
        if cache[neighbor] == nil then
            NODE.kill_subtree_if_no_trees(state, neighbor, cache)
        end
    end

    NODE.remove_node(state, node)

    -- Create branch containing just this node.
    BRANCH.add_branch(state, node)
end

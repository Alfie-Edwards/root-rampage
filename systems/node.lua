require "states.node"

NODE = {}

function NODE.add_node(x, y, parent_id, state, type, branch_id)
    local node = NodeState(x, y, type)
    state.nodes:add(node, x, y)
    if parent_id ~= nil then
        NODE.connect(state, node.id, parent_id)
    end
    state.newest_node = node.id

    if parent_id == nil then
        branch_id = BRANCH.add_branch(state, node.id)
    elseif branch_id == nil then
        branch_id = BRANCH.add_branch(state, parent_id, node.id)
    else
        BRANCH.extend(state, branch_id, node.id)
    end

    return node.id, branch_id
end

function NODE.from_id(state, node_id)
    return nil_coalesce(state.nodes.item_map[node_id], state.ghost_nodes[node_id])
end


function NODE.connect(state, a_id, b_id)
    local a = NODE.from_id(state, a_id)
    local b = NODE.from_id(state, b_id)
    PropertyTable.append(a.neighbors, b_id)
    PropertyTable.append(b.neighbors, a_id)
end

function NODE.disconnect(state, a_id, b_id)
    local a = NODE.from_id(state, a_id)
    local b = NODE.from_id(state, b_id)
    PropertyTable.remove_value(a.neighbors, b_id)
    PropertyTable.remove_value(b.neighbors, a_id)
end

function NODE.are_connected(state, a_id, b_id)
    local b = NODE.from_id(state, b_id)
    return value_in(a_id, b.neighbors:_raw(), pairs)
end

function NODE.remove_node(state, node_id)
    state.ghost_nodes[node_id] = NODE.from_id(state, node_id)
    state.nodes:remove(node_id)
end

function NODE.is_dead(state, node_id)
    return state.nodes.item_map[node_id] == nil
end

function NODE.do_to_subtree(state, node_id, func, seen)
    seen = nil_coalesce(seen, {})
    if seen[node_id] then
        return
    end
    func(node_id)
    seen[node_id] = true
    local node = NODE.from_id(state, node_id)
    for _, neighbor in pairs(node.neighbors) do
        if not seen[neighbor] then
            NODE.do_to_subtree(state, neighbor, func, seen)
        end
    end
end

function NODE.kill_subtree_if_no_trees(state, node_id, cache)
    cache = nil_coalesce(cache, {})

    local function any_trees(node_id)
        if cache[node_id] ~= nil then
            return cache[node_id]
        else
            cache[node_id] = false
        end
        local node = NODE.from_id(state, node_id)
        if node.is_tree then
            return true
        else
            for _, neighbor in pairs(node.neighbors) do
                if any_trees(neighbor) then
                    cache[node_id] = true
                    return true
                end
            end
            return false
        end
    end

    if not any_trees(node_id) then
        NODE.do_to_subtree(state, node_id,
            function(node_id)
                NODE.remove_node(state, node_id)
            end
        )
    end
end

function NODE.cut(state, node_id)
    if NODE.is_dead(state, node_id) then
        return
    end

    local node = NODE.from_id(state, node_id)

    -- Cache neighbors.
    local neighbors = shallow_copy(node.neighbors)
    for _, neighbor in pairs(neighbors) do
        NODE.disconnect(state, node_id, neighbor)
    end

    local branch_map = shallow_copy(node.branch_map)
    for branch_id, indices in pairs(branch_map) do
        table.sort(indices)
        for i = PropertyTable.len(indices), 1, -1 do
            BRANCH.cut(state, BRANCH.from_id(state, branch_id), indices[i])
        end
    end

    local cache = {}
    for _, neighbor in pairs(neighbors) do
        if cache[neighbor] == nil then
            NODE.kill_subtree_if_no_trees(state, neighbor, cache)
        end
    end

    NODE.remove_node(state, node_id)

    -- Create branch containing just this node.
    BRANCH.add_branch(state, node_id)
end

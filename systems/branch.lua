require "states.hacking"
require "systems.node"

BRANCH = {
    LINE_WIDTH = 5,
    WITHER_TIME = 3,
    COLOR = {0.2, 0.1, 0, 1},
    DEAD_COLOR = {0.1, 0.1, 0.05, 1},
}

function BRANCH.update(state, inputs)
    for _, branch in pairs(state.branches) do
        local base_id = BRANCH.base(state, branch)
        if branch.t_dead == NEVER and (base_id == nil or NODE.is_dead(state, base_id)) then
            if branch.length < 2 then
                BRANCH.remove(state, branch)
            else
                BRANCH.kill(state, branch)
            end
        elseif branch.t_dead ~= NEVER and (state.t - branch.t_dead) >= BRANCH.WITHER_TIME then
            BRANCH.remove(state, branch)
        end
    end
end

function BRANCH.draw(state, inputs, dt)
    for _, branch in pairs(state.branches) do
        if branch.length > 1 then
            local base = NODE.from_id(state, BRANCH.base(state, branch))
            local tip = NODE.from_id(state, BRANCH.tip(state, branch))
            local color = BRANCH.COLOR
            local line_width = BRANCH.LINE_WIDTH
            if branch.t_dead ~= NEVER then
                local multiplier = 1 - math.max(0, (state.t + dt - branch.t_dead) / BRANCH.WITHER_TIME)
                line_width = BRANCH.LINE_WIDTH * multiplier
                color = {
                    BRANCH.DEAD_COLOR[1] + (BRANCH.COLOR[1] - BRANCH.DEAD_COLOR[1]) * multiplier,
                    BRANCH.DEAD_COLOR[2] + (BRANCH.COLOR[2] - BRANCH.DEAD_COLOR[2]) * multiplier,
                    BRANCH.DEAD_COLOR[3] + (BRANCH.COLOR[3] - BRANCH.DEAD_COLOR[3]) * multiplier,
                    BRANCH.DEAD_COLOR[4] + (BRANCH.COLOR[4] - BRANCH.DEAD_COLOR[4]) * multiplier,
                }
            end
            love.graphics.setColor(branch.color or color)
            love.graphics.setLineWidth(line_width)
            love.graphics.line(branch.points:_raw())

            -- love.graphics.setColor({1, 1, 1, 1})
            -- love.graphics.points(branch.points:_raw())

            if tip and state.roots.grow_node ~= tip.id then
                local neighbor = NODE.from_id(state, first_value(tip.neighbors))
                if neighbor then
                    local v = Vector(neighbor.x, neighbor.y,
                                     tip.x, tip.y)
                    BRANCH.draw_spike(
                        tip.x,
                        tip.y,
                        v:direction_x(),
                        v:direction_y(),
                        -line_width * 1.2, color,
                        line_width)
                end
            end

            if base and state.roots.grow_node ~= base.id and iter_size(base.neighbors) == 1 then
                local neighbor = NODE.from_id(state, first_value(base.neighbors))
                if neighbor then
                    local v = Vector(neighbor.x, neighbor.y,
                                     base.x, base.y)
                    BRANCH.draw_spike(
                        base.x,
                        base.y,
                        v:direction_x(),
                        v:direction_y(),
                        -line_width * 0.2, color,
                        line_width)
                end
            end
        end
    end
end

function BRANCH.draw_spike(x, y, dir_x, dir_y, extension, color, line_width)
    if line_width == nil then
        line_width = BRANCH.LINE_WIDTH
    end
    love.graphics.setColor(color or BRANCH.COLOR)
    love.graphics.circle("fill", x, y, line_width / 2)
    love.graphics.polygon("fill",
        x - dir_y * line_width / 2,
        y + dir_x * line_width / 2,
        x - dir_x * line_width / 2,
        y - dir_y * line_width / 2,
        x + dir_y * line_width / 2,
        y - dir_x * line_width / 2,
        x + dir_x * (extension + line_width * 2),
        y + dir_y * (extension + line_width * 2)
    )
end

function BRANCH.get_if_tip(state, node_id)
    local node = NODE.from_id(state, node_id)
    for branch_id, indices in pairs(node.branch_map) do
        local branch = BRANCH.from_id(state, branch_id)
        if indices[iter_size(indices)] == branch.length then
            return branch.id
        end
    end
    return nil
end

function BRANCH.is_dead(state, branch_id)
    local branch = BRANCH.from_id(state, branch_id)
    if branch == nil then
        return true
    end
    return branch.t_dead <= state.t
end

function BRANCH.remove(state, branch)
    PropertyTable.remove_value(state.branches, branch)
    for node_id in ipairs(branch.node_list:_raw()) do
        state.ghost_nodes[node_id] = nil
    end
end

function BRANCH.kill(state, branch)
    branch.t_dead = state.t
end

function BRANCH.tip(state, branch)
    if branch.length < 1 then
        return nil
    end
    return branch.node_list[branch.length]
end

function BRANCH.base(state, branch)
    if branch.length < 1 then
        return nil
    end
    return branch.node_list[1]
end

function BRANCH.from_id(state, branch_id)
    return state.branches[branch_id]
end

function BRANCH.add_branch(state, base_id, tip_id)
    assert(base_id == nil or base_id ~= tip_id)
    local branch = BranchState(state.id_tracker)
    state.id_tracker = state.id_tracker + 1

    state.branches[branch.id] = branch
    if base_id ~= nil then
        BRANCH.extend(state, branch.id, base_id)
    end
    if tip_id ~= nil then
        BRANCH.extend(state, branch.id, tip_id)
    end
    return branch.id
end

function BRANCH.extend(state, branch_id, node_id)
    local branch = BRANCH.from_id(state, branch_id)
    local node = NODE.from_id(state, node_id)

    PropertyTable.append(branch.points, node.x)
    PropertyTable.append(branch.points, node.y)
    branch.length = branch.length + 1

    if node.branch_map[branch_id] == nil then
        node.branch_map[branch_id] = PropertyTable()
    end
    PropertyTable.append(node.branch_map[branch_id], branch.length)
    branch.node_list[branch.length] = node_id
end

function BRANCH.cut(state, branch, i)
    local n = branch.length
    branch.length = i - 1
    local new_branch_id = BRANCH.add_branch(state)
    for j = i, n do
        local node = NODE.from_id(state, branch.node_list[j])
        branch.points[(2 * j - 1)] = nil
        branch.points[(2 * j)] = nil
        branch.node_list[j] = nil

        if node.branch_map[branch.id] ~= nil then
            local m = iter_size(node.branch_map[branch.id])
            for k = 1, m do
                if node.branch_map[branch.id][k] >= i then
                    node.branch_map[branch.id][k] = nil
                end
            end
            if iter_size(node.branch_map[branch.id]) == 0 then
                node.branch_map[branch.id] = nil
            end
        end
        if j > i then
            BRANCH.extend(state, new_branch_id, node.id)
        end
    end
end

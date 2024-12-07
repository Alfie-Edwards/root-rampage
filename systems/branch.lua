require "states.hacking"

BRANCH = {
    LINE_WIDTH = 5,
    WITHER_TIME = 3,
    COLOR = {0.2, 0.1, 0, 1},
    DEAD_COLOR = {0.1, 0.1, 0.05, 1},
}

function BRANCH.update(state, inputs)
    for _, branch in pairs(state.branches) do
        local base = BRANCH.base(branch)
        if branch.t_dead == NEVER and (base == nil or NODE.is_dead(state, base)) then
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
            local base = BRANCH.base(branch)
            local tip = BRANCH.tip(branch)
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
            love.graphics.setColor(color)
            love.graphics.setLineWidth(line_width)
            love.graphics.line(branch.points)

            -- love.graphics.setColor({1, 1, 1, 1})
            -- love.graphics.points(branch.points)

            if state.roots.selected ~= tip then
                local neighbor = first_value(tip.neighbors)
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

            if iter_size(base.neighbors) == 1 then
                local neighbor = first_value(base.neighbors)
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

function BRANCH.get_if_tip(state, node)
    for branch_id, indices in pairs(node.branch_map) do
        local branch = state.branches[branch_id]
        if indices[#indices] == branch.length then
            return branch
        end
    end
    return nil
end

function BRANCH.remove(state, branch)
    PropertyTable.remove_value(state.branches, branch)
    for _, node in pairs(branch.node_list) do
        node.branch_map[branch.id] = nil
    end
end

function BRANCH.kill(state, branch)
    branch.t_dead = state.t
end

function BRANCH.tip(branch)
    if branch.length < 1 then
        return nil
    end
    return branch.node_list[branch.length]
end

function BRANCH.base(branch)
    if branch.length < 1 then
        return nil
    end
    return branch.node_list[1]
end

function BRANCH.add_branch(state, base, tip)
    assert(base == nil or base ~= tip)
    local branch = BranchState(state.id_tracker)
    state.id_tracker = state.id_tracker + 1

    state.branches[branch.id] = branch
    if base ~= nil then
        BRANCH.extend(branch, base)
    end
    if tip ~= nil then
        BRANCH.extend(branch, tip)
    end
    return branch
end

function BRANCH.extend(branch, node)
    table.insert(branch.points, node.x)
    table.insert(branch.points, node.y)
    branch.length = branch.length + 1

    if node.branch_map[branch.id] == nil then
        node.branch_map[branch.id] = {}
    end
    table.insert(node.branch_map[branch.id], branch.length)
    branch.node_list[branch.length] = node
end

function BRANCH.cut(state, branch, i)
    local n = branch.length
    branch.length = i - 1
    local new_branch = BRANCH.add_branch(state)
    for j = i, n do
        local node = branch.node_list[j]
        branch.points[(2 * j - 1)] = nil
        branch.points[(2 * j)] = nil
        branch.node_list[j] = nil

        if node.branch_map[branch.id] ~= nil then
            local m = #node.branch_map[branch.id]
            for k = 1, m do
                if node.branch_map[branch.id][k] >= i then
                    node.branch_map[branch.id][k] = nil
                end
            end
            if #(node.branch_map[branch.id]) == 0 then
                node.branch_map[branch.id] = nil
            end
        end
        if j > i then
            BRANCH.extend(new_branch, node)
        end
    end
end

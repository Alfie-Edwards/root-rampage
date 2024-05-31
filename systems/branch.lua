require "states.hacking"

BRANCH = {
    LINE_WIDTH = 5,
    WITHER_TIME = 3,
    COLOR = {0.2, 0.1, 0, 1},
    DEAD_COLOR = {0.1, 0.1, 0.05, 1},
}

function BRANCH.update(state, inputs)
    for _, branch in ipairs(state.branches) do
        BRANCH.update_tip(branch)
        if branch.base.is_dead and (state.t - branch.base.t_dead) > BRANCH.WITHER_TIME then
            BRANCH.cull(state, branch)
        end
    end
end

function BRANCH.draw(state, inputs, dt)
    for _, branch in ipairs(state.branches) do
        if branch.length > 1 then
            local color = BRANCH.COLOR
            local line_width = BRANCH.LINE_WIDTH
            if branch.base.is_dead then
                local multiplier = 1 - math.max(0, (state.t + dt - branch.base.t_dead) / BRANCH.WITHER_TIME)
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

            if state.roots.selected ~= branch.tip then
                local v = Vector(branch.tip.parent.x, branch.tip.parent.y,
                                     branch.tip.x, branch.tip.y)
                BRANCH.draw_spike(
                    branch.tip.x,
                    branch.tip.y,
                    v:direction_x(),
                    v:direction_y(),
                    -line_width * 1.2, color,
                    line_width)
            end

            if branch.base.parent == nil then
                local v = Vector(branch.base.children[branch.child_index].x,
                                     branch.base.children[branch.child_index].y,
                                     branch.base.x, branch.base.y)
                BRANCH.draw_spike(
                    branch.base.x,
                    branch.base.y,
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

function BRANCH.trim_start(state, branch)
    if branch.base.children[branch.child_index] == nil then
        BRANCH.cull(state, branch)
    else
        branch.base = branch.base.children[branch.child_index]
        branch.child_index = 1
    end
    table.remove(branch.points, 1)
    table.remove(branch.points, 1)
    branch.length = branch.length - 1
end

function BRANCH.trim_end(branch)
    assert(branch.tip.parent ~= nil)
    branch.tip = branch.tip.parent
    table.remove(branch.points, #branch.points)
    table.remove(branch.points, #branch.points)
    branch.length = branch.length - 1
end

function BRANCH.trim_end_to(branch, node)
    while branch.tip ~= node do
        BRANCH.trim_end(branch)
    end
end

function BRANCH.cull(state, branch)
    remove_value(state.branches, branch)
    NODE.cull(state, branch.base)
    local next = branch.base.children[branch.child_index]
    while next ~= nil do
        NODE.cull(state, next)
        next = next.children[1]
    end
end

function BRANCH.add_branch(state, base, child_index)
    local branch = BranchState(base, child_index)
    BRANCH.update_tip(branch)
    table.insert(state.branches, branch)
    return branch
end

function BRANCH.get_branches(state, base)
    local branches = {}
    for _, branch in ipairs(state.branches) do
        if branch.base == base then
            table.insert(branches, branch)
        end
    end
    return branches
end

function BRANCH.get_branch(state, base, child_index)
    for _, branch in ipairs(state.branches) do
        if branch.base == base and branch.child_index == child_index then
            return branch
        end
    end
    return nil
end

function BRANCH.get_main_branch(state, node)
    -- Get the branch this node was originally created on.
    local base
    local child_index

    if node.parent == nil then
        base = node
        child_index = 1
    else
        local prev = node
        base = node.parent
        while base.children[1] == prev and base.parent ~= nil do
            prev = base
            base = base.parent
        end

        child_index = get_key(base.children, prev)
    end

    local branch = BRANCH.get_branch(state, base, child_index)
    assert(branch ~= nil)
    return branch
end

function BRANCH.update_tip(branch)
    if branch.length == 1 then
        if branch.tip.children[branch.child_index] then
            branch.tip = branch.tip.children[branch.child_index]
            table.insert(branch.points, branch.tip.x)
            table.insert(branch.points, branch.tip.y)
            branch.length = branch.length + 1
        else
            return
        end
    end

    while branch.tip.children[1] ~= nil do
        branch.tip = branch.tip.children[1]
        table.insert(branch.points, branch.tip.x)
        table.insert(branch.points, branch.tip.y)
        branch.length = branch.length + 1
    end
end

require "utils"
require "time"
require "roots.branch"
require "roots.tree_spot"
require "roots.terminal"
require "roots.node"

AttackState = {
    READY = 1,
    WINDUP = 2,
    ATTACKING = 3,
    COOLDOWN = 4,
}

Roots = {
    SPEED = 2,
    ATTACK_SPEED = 7,
    ATTACK_WINDUP_SPEED = 0.5,
    ATTACK_WINDUP_TIME = 0.3,
    ATTACK_TIME = 0.1,
    ATTACK_CD = 4,
    KILL_RADIUS = 12,

    nodes = nil,
    branches = nil,
    selected = nil,
    tree_spots = nil,
    terminals = nil,
    state = nil,
    t_attack = nil,
}
setup_class("Roots")

function Roots.new()
    local obj = {}
    setup_instance(obj, Roots)

    obj.nodes = {}
    obj.branches = {}
    obj.tree_spots = {}
    obj.terminals = {}
    obj.state = {
        selected = nil,
        grow_node = nil,
        new_pos = nil,
        mouse_pos = nil,
        valid = nil,
        speed = nil,
        tree_spot = nil,
        timer = nil,
        message = nil,
    }

    return obj
end

function Roots:get_attack_state()
    if self.t_attack == nil then
        return AttackState.READY
    elseif (t - self.t_attack) < Roots.ATTACK_WINDUP_TIME then
        return AttackState.WINDUP
    elseif (t - self.t_attack) < (Roots.ATTACK_WINDUP_TIME + Roots.ATTACK_TIME) then
        return AttackState.ATTACKING
    elseif (t - self.t_attack) < (Roots.ATTACK_WINDUP_TIME + Roots.ATTACK_TIME + Roots.ATTACK_CD) then
        return AttackState.COOLDOWN
    else
        return AttackState.READY
    end
end

function Roots:add_tree_spot(tree_spot)
    assert(tree_spot ~= nil)
    assert(tree_spot.roots == nil)
    table.insert(self.tree_spots, tree_spot)
    tree_spot.roots = self
end

function Roots:remove_tree_spot(tree_spot)
    assert(tree_spot ~= nil)
    assert(tree_spot.roots == self)
    remove_value(self.tree_spots, tree_spot)
end

function Roots:add_terminal(terminal)
    assert(terminal ~= nil)
    assert(terminal.roots == nil)
    table.insert(self.terminals, terminal)
    terminal.roots = self
end

function Roots:remove_terminal(terminal)
    assert(terminal ~= nil)
    assert(terminal.roots == self)
    remove_value(self.terminals, terminal)
end

function Roots:add_branch(branch)
    assert(branch ~= nil)
    assert(branch.roots == nil)
    table.insert(self.branches, branch)
    branch.roots = self
end

function Roots:remove_branch(branch)
    assert(branch ~= nil)
    assert(branch.roots == self)
    remove_value(self.branches, branch)
end

function Roots:add_node(node)
    assert(node ~= nil)
    assert(node.roots == nil)
    table.insert(self.nodes, node)
    node.roots = self
end

function Roots:remove_node(node)
    assert(node ~= nil)
    assert(node.roots == self)
    remove_value(self.nodes, node)
end

function Roots:get_branches(base)
    local branches = {}
    for _,branch in ipairs(self.branches) do
        if branch.base == base then
            table.insert(branches, branch)
        end
    end
    return branches
end

function Roots:get_branch(base, child_index)
    for _,branch in ipairs(self.branches) do
        if branch.base == base and branch.child_index == child_index then
            return branch
        end
    end
    return nil
end

function Roots:get_within_radius(x, y, radius)
    local res = {}
    for _, node in ipairs(self.nodes) do
        if not node.is_dead then
            local dist = sq_dist(x, y, node.x, node.y)
            if dist < radius ^ 2 then
                table.insert(res, node)
            end
        end
    end
    return res
end

function Roots:get_closest_node(x, y)
    local closest = nil
    local dist = nil
    for _, node in ipairs(self.nodes) do
        if not node.is_dead then
            local new_dist = sq_dist(x, y, node.x, node.y)
            if dist == nil or new_dist < dist then
                closest = node
                dist = new_dist
            end
        end
    end
    return closest
end

function Roots:mousepressed(x, y, button)
    if button == 1 then
        self.state.selected = self.state.grow_node
    elseif button == 2 then
        if self:get_attack_state() == AttackState.READY and love.mouse.isDown(1) then
            self.t_attack = t
        end
    end
end

function Roots:mousereleased(x, y, button)
    if button == 1 then
        self.state.selected = nil
    end
end

function Roots:find_tree_spot(x, y)
    for _, tree_spot in ipairs(self.tree_spots) do
        if tree_spot.node == nil and sq_dist(x, y, tree_spot.x, tree_spot.y) < TreeSpot.RADIUS ^ 2 then
            return tree_spot
        end
    end
    return nil
end

function Roots:find_terminal(x, y)
    for _, terminal in ipairs(self.terminals) do
        if terminal.node == nil and sq_dist(x, y, terminal.x, terminal.y) < Terminal.RADIUS ^ 2 then
            return terminal
        end
    end
    return nil
end

function Roots:update_state()
    local state = self.state
    state.mouse_pos = canvas:screen_to_canvas(love.mouse.getX(), love.mouse.getY())

    if state.selected ~= nil and state.timer == nil then
        state.grow_node = state.selected
    else
        state.grow_node = self:get_closest_node(state.mouse_pos.x, state.mouse_pos.y)
    end

    if state.grow_node == nil then
        self.state = {}
        return
    end

    local atack_state = self:get_attack_state()
    if atack_state == AttackState.WINDUP then
        state.speed = Roots.ATTACK_WINDUP_SPEED
    elseif atack_state == AttackState.ATTACKING then
        state.speed = Roots.ATTACK_SPEED
    else
        state.speed = Roots.SPEED
    end

    local v = Vector.new(state.grow_node.x, state.grow_node.y,
                         state.mouse_pos.x, state.mouse_pos.y)

    if v:length() == 0 then
        self.state = {}
        return
    end

    state.new_pos = {x = state.grow_node.x + v:direction_x() * state.speed,
                     y = state.grow_node.y + v:direction_y() * state.speed}

    if v:length() < state.speed then
        state.valid = false
    elseif self:get_closest_node(state.new_pos.x, state.new_pos.y) ~= state.grow_node then
        state.valid = false
    elseif level:solid(state.new_pos) then
        state.valid = false
    else
        state.valid = true
    end

    if state.timer == nil then
        state.tree_spot = self:find_tree_spot(state.new_pos.x, state.new_pos.y)
        if state.tree_spot ~= nil then
            state.timer = t
        else
            state.terminal = self:find_terminal(state.new_pos.x, state.new_pos.y)
            if state.terminal ~= nil then
                state.timer = t
            end
        end
    else
        if state.tree_spot ~= nil and (state.tree_spot.node ~= nil or state.selected == nil) then
            state.timer = nil
        end
        if state.terminal ~= nil and (state.terminal.node ~= nil or state.selected == nil) then
            state.timer = nil
        end
    end

    state.message = nil
    if state.tree_spot ~= nil and state.tree_spot.node == nil then
        if state.timer == nil then
            state.message = TreeSpot.TOOLTIP
        else
            state.message = TreeSpot.TOOLTIP2
        end
    end

    if state.message == nil then
        if state.terminal ~= nil and state.terminal.node == nil then
            if state.timer == nil then
                state.message = Terminal.TOOLTIP
            else
                state.message = Terminal.TOOLTIP2
            end
        end
    end

    if state.message == nil then
        local door_pos = door:get_center()
        if sq_dist(state.mouse_pos.x, state.mouse_pos.y, door_pos.x, door_pos.y) < 32 ^ 2 then
            if door.is_open then
                state.message = Door.TOOLTIP_OPEN
            else
                state.message = Door.TOOLTIP_CLOSED
            end
        end
    end
end

function Roots:update(dt)
    if self.state.selected ~= nil and self.state.selected.is_dead then
        self.state.selected  = nil
    end
    self:update_state()

    if love.mouse.isDown(1) and self.state.selected ~= nil then
        if self.state.valid then
            if self.state.tree_spot ~= nil and self.state.tree_spot.node == nil then
                if (t - self.state.timer) > TreeSpot.TIME then
                    self.state.tree_spot:create_node(self.state.selected)
                end
            elseif self.state.terminal ~= nil and self.state.terminal.node == nil then
                if (t - self.state.timer) > Terminal.TIME then
                    self.state.terminal:create_node(self.state.selected)
                end
            else
                self.state.selected = Node.new(self.state.new_pos.x, self.state.new_pos.y, self.state.grow_node, self)
            end
        end
        if self:get_attack_state() == AttackState.ATTACKING and
                sq_dist(player.pos.x, player.pos.y, self.state.selected.x, self.state.selected.y) < Roots.KILL_RADIUS ^ 2 then
            player:kill()
        end
    end
    for _, branch in ipairs(self.branches) do
        branch:update(dt)
    end
    for _, tree_spot in ipairs(self.tree_spots) do
        tree_spot:update(dt)
    end
    for _, terminal in ipairs(self.terminals) do
        terminal:update(dt)
    end
end

function Roots:draw()
    for _, branch in ipairs(self.branches) do
        branch:draw()
    end

    if self.state.grow_node ~= nil then
        local attack_state = self:get_attack_state()
        local color = nil
        if attack_state == AttackState.ATTACKING then
            color = {0.4, 0.08, 0.02, 1}
        end
        local v = Vector.new(self.state.grow_node.x, self.state.grow_node.y,
                             self.state.new_pos.x, self.state.new_pos.y)
        Branch.draw_spike(
            self.state.grow_node.x,
            self.state.grow_node.y,
            v:direction_x(),
            v:direction_y(),
            self.state.speed, color)
    end

    if self.state.timer ~= nil and self.state.selected ~= nil then
        if self.state.tree_spot ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({self.state.mouse_pos.x, self.state.mouse_pos.y + 20,
                                self.state.tree_spot.x, self.state.tree_spot.y})
            local v = Vector.new(self.state.selected.x, self.state.selected.y,
                                 self.state.tree_spot.x, self.state.tree_spot.y)
            Branch.draw_spike(
                self.state.selected.x,
                self.state.selected.y,
                v:direction_x(),
                v:direction_y(),
                Roots.SPEED)
        end

        if self.state.terminal ~= nil then
            love.graphics.setColor({0, 0, 0, 0.4})
            love.graphics.setLineWidth(1)
            love.graphics.line({self.state.mouse_pos.x, self.state.mouse_pos.y + 20,
                                self.state.terminal.x, self.state.terminal.y})
            local v = Vector.new(self.state.selected.x, self.state.selected.y,
                                 self.state.terminal.x, self.state.terminal.y)
            Branch.draw_spike(
                self.state.selected.x,
                self.state.selected.y,
                v:direction_x(),
                v:direction_y(),
                Roots.SPEED)
        end
    end

    for _, tree_spot in ipairs(self.tree_spots) do
        tree_spot:draw()
    end

    for _, terminal in ipairs(self.terminals) do
        terminal:draw()
    end

    if self.state.message ~= nil then
        draw_centred_text(self.state.message, self.state.mouse_pos.x, self.state.mouse_pos.y - 10, {1, 1, 1, 1}, {0, 0, 0, 0.4})
    end

    if self.state.timer ~= nil then
        local angle = math.min(1, (t - self.state.timer) / TreeSpot.TIME) * math.pi * 2
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.circle("fill", self.state.mouse_pos.x, self.state.mouse_pos.y + 20, 12)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.arc("fill", self.state.mouse_pos.x, self.state.mouse_pos.y + 20, 10, -math.pi / 2, angle - math.pi / 2)
    end
end

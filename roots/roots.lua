require "utils"
require "time"
require "roots.branch"
require "roots.tree_spot"
require "roots.terminal"
require "roots.node"

AttackState = {
    READY = 1,
    ATTACKING = 2,
    COOLDOWN = 3,
}

Roots = {
    SPEED = 2,
    ATTACK_SPEED = 7,
    ATTACK_TIME = 0.4,
    ATTAK_CD = 2,
    KILL_RADIUS = 12,

    nodes = nil,
    branches = nil,
    selected = nil,
    tree_spots = nil,
    terminals = nil,
    prospective = nil,
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
    obj.prospective = {
        selection = nil,
        x = nil,
        y = nil,
        dir_x = nil,
        dir_y = nil,
        valid = nil,
        mouse_x = nil,
        mouse_y = nil,
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
    elseif (t - self.t_attack) < Roots.ATTACK_TIME then
        return AttackState.ATTACKING
    elseif (t - self.t_attack) < (Roots.ATTACK_TIME + Roots.ATTAK_CD) then
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
            local dist = (x - node.x) ^ 2 + (y - node.y) ^ 2
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
            local new_dist = ((x - node.x) ^ 2 + (y - node.y) ^ 2) ^ (1 / 2)
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
        self.selected = self.prospective.selection
    elseif button == 2 then
        if self:get_attack_state() == AttackState.READY and love.mouse.isDown(1) then
            self.t_attack = t
        end
    end
end

function Roots:mousereleased(x, y, button)
    if button == 1 then
        self.selected = nil
    end
end

function Roots:find_tree_spot(x, y)
    for _, tree_spot in ipairs(self.tree_spots) do
        if ((x - tree_spot.x) ^ 2 + (y - tree_spot.y) ^ 2) < TreeSpot.RADIUS ^ 2 then
            return tree_spot
        end
    end
    return nil
end

function Roots:find_terminal(x, y)
    for _, terminal in ipairs(self.terminals) do
        if ((x - terminal.x) ^ 2 + (y - terminal.y) ^ 2) < Terminal.RADIUS ^ 2 then
            return terminal
        end
    end
    return nil
end

function Roots:update_prospective()
    self.prospective.mouse_x, self.prospective.mouse_y = canvas:screen_to_canvas(love.mouse.getX(), love.mouse.getY())

    if self.selected ~= nil then
        self.prospective.selection = self.selected
    else
        self.prospective.selection = self:get_closest_node(self.prospective.mouse_x, self.prospective.mouse_y)
    end

    if self.prospective.selection == nil then
        self.prospective = {}
        return
    end

    if self.selected ~= nil and self.prospective.timer ~= nil and
        ((self.prospective.tree_spot ~= nil and self.prospective.tree_spot.node == nil) or
         (self.prospective.terminal ~= nil and self.prospective.terminal.node == nil)) then
        return
    end

    if self:get_attack_state() == AttackState.ATTACKING then
        self.prospective.speed = Roots.ATTACK_SPEED
    else
        self.prospective.speed = Roots.SPEED
    end

    local dx = self.prospective.mouse_x - self.prospective.selection.x
    local dy = self.prospective.mouse_y - self.prospective.selection.y

    if dx == 0 and dy == 0 then
        self.prospective = {}
        return
    end

    local dist = (dx ^ 2 + dy ^ 2) ^ (1 / 2)
    self.prospective.dir_x = dx / dist
    self.prospective.dir_y = dy / dist
    self.prospective.x = self.prospective.selection.x + self.prospective.dir_x * self.prospective.speed
    self.prospective.y = self.prospective.selection.y + self.prospective.dir_y * self.prospective.speed

    if dist < self.prospective.speed then
        self.prospective.valid = false
    elseif self:get_closest_node(self.prospective.x, self.prospective.y) ~= self.prospective.selection then
        self.prospective.valid = false
    elseif level:solid({x = self.prospective.x, y = self.prospective.y}) then
        self.prospective.valid = false
    else
        self.prospective.valid = true
    end

    local new_tree_spot = self:find_tree_spot(self.prospective.x, self.prospective.y)
    if new_tree_spot ~= self.prospective.tree_spot then
        if new_tree_spot == nil or new_tree_spot.node ~= nil then
            self.prospective.timer = nil
        else
            self.prospective.timer = t
        end
    end
    self.prospective.tree_spot = new_tree_spot
    if self.prospective.tree_spot ~= nil then
        if self.prospective.timer == nil and self.prospective.tree_spot.node == nil and self.selected ~= nil then
            self.prospective.timer = t
        end
        if self.prospective.timer ~= nil and self.prospective.tree_spot.node ~= nil or self.selected == nil then
            self.prospective.timer = nil
        end
    end

    self.prospective.message = nil
    if self.prospective.tree_spot ~= nil and self.prospective.tree_spot.node == nil then
        if self.prospective.timer == nil then
            self.prospective.message = TreeSpot.TOOLTIP
        else
            self.prospective.message = TreeSpot.TOOLTIP2
        end
    end

    if self.prospective.tree_spot == nil then
        local new_terminal = self:find_terminal(self.prospective.x, self.prospective.y)
        if new_terminal ~= self.prospective.terminal then
            if new_terminal == nil or new_terminal.node ~= nil then
                self.prospective.timer = nil
            else
                self.prospective.timer = t
            end
        end
        self.prospective.terminal = new_terminal
        if self.prospective.terminal ~= nil then
            if self.prospective.timer == nil and self.prospective.terminal.node == nil and self.selected ~= nil then
                self.prospective.timer = t
            end
            if self.prospective.timer ~= nil and self.prospective.terminal.node ~= nil or self.selected == nil then
                self.prospective.timer = nil
            end
        end

        self.prospective.message = nil
        if self.prospective.terminal ~= nil and self.prospective.terminal.node == nil then
            if self.prospective.timer == nil then
                self.prospective.message = Terminal.TOOLTIP
            else
                self.prospective.message = Terminal.TOOLTIP2
            end
        end
    end
end

function Roots:update(dt)
    self:update_prospective()

    if love.mouse.isDown(1) and self.selected ~= nil then
        if self.prospective.valid then
            if self.prospective.tree_spot ~= nil and self.prospective.tree_spot.node == nil then
                if (t - self.prospective.timer) > TreeSpot.TIME then
                    self.selected = self.prospective.tree_spot:create_node(self.selected)
                end
            elseif self.prospective.terminal ~= nil and self.prospective.terminal.node == nil then
                if (t - self.prospective.timer) > Terminal.TIME then
                    self.selected = self.prospective.terminal:create_node(self.selected)
                end
            else
                self.selected = Node.new(self.prospective.x, self.prospective.y, self.selected, self)
            end
        end
        if self:get_attack_state() == AttackState.ATTACKING and
                (player.pos.x - self.selected.x) ^ 2 + (player.pos.y - self.selected.y) ^ 2 < Roots.KILL_RADIUS ^ 2 then
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

    if self.prospective.selection ~= nil then
        if self:get_attack_state() == AttackState.ATTACKING then
            love.graphics.setColor({0.8, 0.15, 0.1, 1})
        else
            love.graphics.setColor({0.2, 0.1, 0, 1})
        end
        love.graphics.circle("fill", self.prospective.x, self.prospective.y, Branch.LINE_WIDTH / 2)
        love.graphics.polygon("fill",
            self.prospective.selection.x - self.prospective.dir_y * Branch.LINE_WIDTH / 2,
            self.prospective.selection.y + self.prospective.dir_x * Branch.LINE_WIDTH / 2,
            self.prospective.selection.x - self.prospective.dir_x * Branch.LINE_WIDTH / 2,
            self.prospective.selection.y - self.prospective.dir_y * Branch.LINE_WIDTH / 2,
            self.prospective.selection.x + self.prospective.dir_y * Branch.LINE_WIDTH / 2,
            self.prospective.selection.y - self.prospective.dir_x * Branch.LINE_WIDTH / 2,
            self.prospective.x + self.prospective.dir_x * Branch.LINE_WIDTH * 2,
            self.prospective.y + self.prospective.dir_y * Branch.LINE_WIDTH * 2
        )
    end

    if self.prospective.tree_spot ~= nil and self.prospective.tree_spot.node == nil then
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.setLineWidth(1)
        love.graphics.line({self.prospective.mouse_x, self.prospective.mouse_y + 20, self.prospective.tree_spot.x, self.prospective.tree_spot.y})
    end

    if self.prospective.terminal ~= nil and self.prospective.terminal.node == nil then
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.setLineWidth(1)
        love.graphics.line({self.prospective.mouse_x, self.prospective.mouse_y + 20, self.prospective.terminal.x, self.prospective.terminal.y})
    end

    for _, tree_spot in ipairs(self.tree_spots) do
        tree_spot:draw()
    end

    for _, terminal in ipairs(self.terminals) do
        terminal:draw()
    end

    if self.prospective.message ~= nil then
        draw_centred_text(self.prospective.message, self.prospective.mouse_x, self.prospective.mouse_y - 10, {1, 1, 1, 1}, {0, 0, 0, 0.4})
    end

    if self.prospective.timer ~= nil then
        local angle = math.min(1, (t - self.prospective.timer) / TreeSpot.TIME) * math.pi * 2
        love.graphics.setColor({0, 0, 0, 0.4})
        love.graphics.circle("fill", self.prospective.mouse_x, self.prospective.mouse_y + 20, 12)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.arc("fill", self.prospective.mouse_x, self.prospective.mouse_y + 20, 10, -math.pi / 2, angle - math.pi / 2)
    end
end

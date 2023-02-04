require "utils"

Roots = {
    SPEED = 2,

    nodes = nil,
    branches = nil,
    selected = nil,
}
setup_class("Roots")

function Roots.new()
    local obj = {}
    setup_instance(obj, Roots)

    obj.nodes = {}
    obj.branches = {}

    return obj
end

function Roots:add_branch(branch)
    assert(branch ~= nil)
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
    for _,branch in pairs(self.branches) do
        if branch.base == base then
            table.insert(branches, branch)
        end
    end
    return branches
end

function Roots:get_branch(base, child_index)
    for _,branch in pairs(self.branches) do
        if branch.base == base and branch.child_index == child_index then
            return branch
        end
    end
    return nil
end

function Roots:get_closest_node(x, y)
    local closest = nil
    local dist = nil
    for _, node in ipairs(self.nodes) do
        local new_dist = (x - node.x) ^ 2 + (y - node.y) ^ 2
        if dist == nil or new_dist < dist then
            closest = node
            dist = new_dist
        end
    end
    return closest
end

function Roots:mousepressed(x, y, button)
    if button == 1 then
        self.selected = self:get_closest_node(x, y)
    end
end

function Roots:mousereleased(x, y, button)
    if button == 1 then
        self.selected = nil
    end
end

function Roots:is_valid_node_pos(x, y)
    -- Crude distance test to prevent self-intersection
    if self:get_closest_node(x, y) ~= self.selected then
        return false
    end
    if level:solid({x = x, y = y}) then
        return false
    end
    return true
end

function Roots:update(dt)
    if love.mouse.isDown(1) and self.selected ~= nil then
        canvas_x, canvas_y = canvas:screen_to_canvas(love.mouse.getX(), love.mouse.getY())
        local dx = canvas_x - self.selected.x
        local dy = canvas_y - self.selected.y
        local dist = 0
        if not (dx == 0  and dy == 0) then
            dist = (dx ^ 2 + dy ^ 2) ^ (1 / 2)
        end
        if dist >= Roots.SPEED then
            local x_new = self.selected.x + (dx * Roots.SPEED / dist)
            local y_new = self.selected.y + (dy * Roots.SPEED / dist)

            if self:is_valid_node_pos(x_new, y_new) then
                self.selected = Node.new(x_new, y_new, self.selected, false, self)
            end
        end
    end
end

function Roots:draw()
    for _, branch in pairs(self.branches) do
        branch:draw()
    end
end

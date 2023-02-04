require "utils"
require "roots.tree_spot"
require "roots.node"

Roots = {
    SPEED = 2,

    nodes = nil,
    branches = nil,
    selected = nil,
    tree_spots = nil,
}
setup_class("Roots")

function Roots.new()
    local obj = {}
    setup_instance(obj, Roots)

    obj.nodes = {}
    obj.branches = {}
    obj.tree_spots = {}

    return obj
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
        local dist = (x - node.x) ^ 2 + (y - node.y) ^ 2
        if dist < radius ^ 2 then
            table.insert(res, node)
        end
    end
    return res
end

function Roots:get_closest_node(x, y)
    local closest = nil
    local dist = nil
    for _, node in ipairs(self.nodes) do
        local new_dist = ((x - node.x) ^ 2 + (y - node.y) ^ 2) ^ (1 / 2)
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

function Roots:find_tree_spot(x, y)
    for _, tree_spot in ipairs(self.tree_spots) do
        if ((x - tree_spot.x) ^ 2 + (y - tree_spot.y) ^ 2) < TreeSpot.RADIUS ^ 2 then
            return tree_spot
        end
    end
    return nil
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
                local tree_spot = self:find_tree_spot(x_new, y_new)
                if tree_spot ~= nil and tree_spot.node == nil then
                    self.selected = tree_spot:create_node(self.selected)
                else
                    self.selected = Node.new(x_new, y_new, self.selected, false, self)
                end
            end
        end
    end
end

function Roots:draw()
    for _, tree_spot in ipairs(self.tree_spots) do
        tree_spot:draw()
    end
    for _, branch in ipairs(self.branches) do
        branch:draw()
    end
    if self.selected == nil then
        canvas_x, canvas_y = canvas:screen_to_canvas(love.mouse.getX(), love.mouse.getY())
        local closest = self:get_closest_node(canvas_x, canvas_y)
        love.graphics.setColor({0.8, 0.8, 0, 0.5})
        love.graphics.circle("fill", closest.x, closest.y, 6)
    end
end

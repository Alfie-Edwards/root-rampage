require "utils"
require "roots.branch"
require "roots.tree_spot"
require "roots.node"

Roots = {
    SPEED = 2,

    nodes = nil,
    branches = nil,
    selected = nil,
    tree_spots = nil,
    prospective = nil,
}
setup_class("Roots")

function Roots.new()
    local obj = {}
    setup_instance(obj, Roots)

    obj.nodes = {}
    obj.branches = {}
    obj.tree_spots = {}
    obj.prospective = {
        node = nil,
        x = nil,
        y = nil,
        mouse_x = nil,
        mouse_y = nil,
        tree_spot = nil,
        timer = nil,
        message = nil,
    }

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

    local dx = self.prospective.mouse_x - self.prospective.selection.x
    local dy = self.prospective.mouse_y - self.prospective.selection.y

    if dx == 0 and dy == 0 then
        self.prospective_point = nil
        return
    end

    local dist = (dx ^ 2 + dy ^ 2) ^ (1 / 2)
    self.prospective.x = self.prospective.selection.x + (dx * Roots.SPEED / dist)
    self.prospective.y = self.prospective.selection.y + (dy * Roots.SPEED / dist)

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
        self.prospective.message = "Grow Tree"
    end
end

function Roots:update(dt)
    self:update_prospective()

    if love.mouse.isDown(1) and self.selected ~= nil then
        if self:is_valid_node_pos(self.prospective.x, self.prospective.y) then
            if self.prospective.tree_spot ~= nil and self.prospective.tree_spot.node == nil then
                if (t - self.prospective.timer) > TreeSpot.TIME then
                    self.selected = self.prospective.tree_spot:create_node(self.selected)
                end
            else
                self.selected = Node.new(self.prospective.x, self.prospective.y, self.selected, false, self)
            end
        end
    end
    for _, branch in ipairs(self.branches) do
        branch:update(dt)
    end
    for _, tree_spot in ipairs(self.tree_spots) do
        tree_spot:update(dt)
    end
end

function Roots:draw()
    for _, branch in ipairs(self.branches) do
        branch:draw()
    end

    if self.prospective.selection ~= nil then
        love.graphics.setLineWidth(Branch.LINE_WIDTH)
        love.graphics.setLineStyle("smooth")
        love.graphics.setColor({0.4, 0.2, 0, 1})
        local projected_x = self.prospective.selection.x + (self.prospective.x - self.prospective.selection.x) * 3 / Roots.SPEED
        local projected_y = self.prospective.selection.y + (self.prospective.y - self.prospective.selection.y) * 3 / Roots.SPEED
        love.graphics.circle("fill", projected_x, projected_y, 4)
    end

    for _, tree_spot in ipairs(self.tree_spots) do
        tree_spot:draw()
    end

    if self.prospective.message ~= nil then
        draw_centred_text(self.prospective.message, self.prospective.mouse_x, self.prospective.mouse_y - 30, {0.2, 0.2, 0.2, 1})
    end

    if self.prospective.timer ~= nil then
        local angle = math.min(1, (t - self.prospective.timer) / TreeSpot.TIME) * math.pi * 2
        love.graphics.setColor({0.2, 0.2, 0.2, 1})
        love.graphics.arc("fill", self.prospective.mouse_x, self.prospective.mouse_y, 10, -math.pi / 2, angle - math.pi / 2)
    end
end

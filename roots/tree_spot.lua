require "utils"
require "roots.node"

TreeSpot = {
    RADIUS = 16,
    TIME = 5,
    TOOLTIP = "Grow tree",

    x = nil,
    y = nil,
    node = nil,
    roots = nil,
}
setup_class("TreeSpot")

function TreeSpot.new(x, y)
    local obj = {}
    setup_instance(obj, TreeSpot)
    assert(x ~= nil)
    assert(y ~= nil)

    obj.x = x
    obj.y = y

    return obj
end

function TreeSpot:create_node(parent)
    assert(self.node == nil)
    self.node = Node.new(self.x, self.y, parent, self.roots)
    self.node.is_tree = true
    return self.node
end

function TreeSpot:update(dt)
    if self.node ~= nil and self.node.is_dead then
        self.node = nil
    end
    if self.roots.prospective.selection ~= nil and
           self.roots.prospective.message == nil and
           (self.x - self.roots.prospective.mouse_x) ^ 2 + (self.y - self.roots.prospective.mouse_y) ^ 2 < TreeSpot.RADIUS ^ 2 then
        self.roots.prospective.message = TreeSpot.TOOLTIP
    end
end

function TreeSpot:draw()
    love.graphics.setLineWidth(1)
    love.graphics.setColor({0.2, 0.4, 0, 0.2})
    love.graphics.circle("line", self.x, self.y, TreeSpot.RADIUS)
    if self.node ~= nil then
        love.graphics.setColor({0.2, 0.4, 0, 1})
        love.graphics.circle("fill", self.x, self.y, TreeSpot.RADIUS * 0.5)
    end
end
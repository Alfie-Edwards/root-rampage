require "utils"
require "roots.node"

TreeSpot = {
    RADIUS = 16,

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
    self.node = Node.new(self.x, self.y, parent, true, self.roots)
    return self.node
end

function TreeSpot:draw()
    love.graphics.setColor({0.2, 0.4, 0, 0.2})
    love.graphics.circle("fill", self.x, self.y, TreeSpot.RADIUS)
    if self.node ~= nil then
    love.graphics.setColor({0.2, 0.4, 0, 1})
        love.graphics.circle("fill", self.x, self.y, TreeSpot.RADIUS * 0.5)
    end
end
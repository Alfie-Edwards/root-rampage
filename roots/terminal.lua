require "utils"
require "roots.node"

Terminal = {
    RADIUS = 16,
    TIME = 5,

    x = nil,
    y = nil,
    node = nil,
    roots = nil,
}
setup_class("Terminal")

function Terminal.new(x, y)
    local obj = {}
    setup_instance(obj, Terminal)
    assert(x ~= nil)
    assert(y ~= nil)

    obj.x = x
    obj.y = y

    return obj
end

function Terminal:create_node(parent)
    assert(self.node == nil)
    self.node = Node.new(self.x, self.y, parent, self.roots)
    self.node.is_terminal = true
    return self.node
end

function Terminal:update(dt)
    if self.node ~= nil and self.node.is_dead then
        self.node = nil
    end
end

function Terminal:draw()
    love.graphics.setLineWidth(1)
    love.graphics.setColor({0.0, 0.2, 0.4, 0.2})
    love.graphics.circle("line", self.x, self.y, Terminal.RADIUS)
    if self.node ~= nil then
        love.graphics.setColor({0, 0.2, 0.4, 1})
        love.graphics.circle("fill", self.x, self.y, Terminal.RADIUS * 0.5)
    end
end
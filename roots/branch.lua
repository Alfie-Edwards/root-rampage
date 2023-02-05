-- A rendering construct.
Branch = {
    LINE_WIDTH = 5,

    base = nil,
    child_index = nil,
    tip = nil
}
setup_class("Branch")

function Branch.new(base, child_index)
    local obj = {}
    setup_instance(obj, Branch)

    assert(base ~= nil)
    assert(child_index ~= nil)
    assert(roots ~= nil)

    obj.base = base
    obj.child_index = child_index
    obj.tip = base
    obj.length = 1
    obj.points = {base.x, base.y}
    obj:update_tip()

    return obj
end

function Branch:trim_start()
    if self.base.children[self.child_index] == nil then
        self.roots:remove_branch(self)
    else
        self.base = self.base.children[self.child_index]
        self.child_index = 1
    end
    table.remove(self.points, 1)
    table.remove(self.points, 1)
    self.length = self.length - 1
end

function Branch:trim_end()
    assert(self.tip.parent ~= nil)
    self.tip = self.tip.parent
    table.remove(self.points, #self.points)
    table.remove(self.points, #self.points)
    self.length = self.length - 1
end

function Branch:trim_end_to(node)
    while self.tip ~= node do
        self:trim_end()
    end
end

function Branch:update_tip()
    if self.length == 1 then
        if self.tip.children[self.child_index] then
            self.tip = self.tip.children[self.child_index]
            table.insert(self.points, self.tip.x)
            table.insert(self.points, self.tip.y)
            self.length = self.length + 1
        end
    end

    while self.tip.children[1] ~= nil do
        self.tip = self.tip.children[1]
        table.insert(self.points, self.tip.x)
        table.insert(self.points, self.tip.y)
        self.length = self.length + 1
    end
end

function Branch:update(dt)
    self:update_tip()
end

function Branch:draw()
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineWidth(5)
    love.graphics.setLineStyle("smooth")
    love.graphics.setColor({0.4, 0.2, 0, 1})
    if self.length > 1 and not self.base.is_dead then
        love.graphics.line(self.points)
    end
end
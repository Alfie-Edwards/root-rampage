-- A rendering construct.
Branch = {
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

    print("Branch created!")
    obj.base = base
    obj.child_index = child_index
    obj.tip = base
    obj.length = 1
    obj.points = {base.x, base.y}

    return obj
end

function Branch:trim_start()
    if self.base.children[self.child_index] == nil then
        self.roots.remove_branch(self)
    else
        self.base = self.base.children[self.child_index]
        self.child_index = 1
    end
    table.remove(self.points, 0)
    table.remove(self.points, 0)
    self.length = self.length - 1
end

function Branch:trim_end()
    assert(self.tip.parent ~= nil)
    self.tip = self.tip.parent
    table.remove(self.points, -1)
    table.remove(self.points, -1)
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


function Branch:draw()
    self:update_tip()
    love.graphics.setLineWidth(5)
    love.graphics.setLineStyle("smooth")
    love.graphics.setColor({0.4, 0.2, 0, 1})
    if self.length > 1 then
        love.graphics.line(self.points)
    end
end
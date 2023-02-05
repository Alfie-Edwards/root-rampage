require "time"

-- A rendering construct.
Branch = {
    LINE_WIDTH = 5,
    WITHER_TIME = 3,
    COLOR = {0.2, 0.1, 0, 1},
    DEAD_COLOR = {0.1, 0.1, 0.05, 1},

    base = nil,
    child_index = nil,
    tip = nil,
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
        self:cull()
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

function Branch:cull()
    self.roots:remove_branch(self)
    self.base:cull()
    local next = self.base.children[self.child_index]
    while next ~= nil do
        next:cull()
        next = next.children[1]
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
    if self.base.is_dead and (t - self.base.t_dead) > Branch.WITHER_TIME then
        self:cull()
    end
end

function Branch:draw()
    if self.length <= 1 then
        return
    end

    love.graphics.setColor(Branch.COLOR)
    love.graphics.setLineWidth(Branch.LINE_WIDTH)
    if self.base.is_dead then
        local multiplier = 1 - math.max(0, (t - self.base.t_dead) / Branch.WITHER_TIME)
        love.graphics.setLineWidth(Branch.LINE_WIDTH * multiplier)
        love.graphics.setColor({
            Branch.DEAD_COLOR[1] + (Branch.COLOR[1] - Branch.DEAD_COLOR[1]) * multiplier,
            Branch.DEAD_COLOR[2] + (Branch.COLOR[2] - Branch.DEAD_COLOR[2]) * multiplier,
            Branch.DEAD_COLOR[3] + (Branch.COLOR[3] - Branch.DEAD_COLOR[3]) * multiplier,
            Branch.DEAD_COLOR[4] + (Branch.COLOR[4] - Branch.DEAD_COLOR[4]) * multiplier,
        })
    end
    love.graphics.line(self.points)
end
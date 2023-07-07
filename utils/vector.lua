Vector = {
    x1 = nil,
    y1 = nil,
    x2 = nil,
    y2 = nil,
}
setup_class(Vector)

function Vector.new(x1, y1, x2, y2)
    local obj = magic_new()
    assert(x1 ~= nil)
    assert(y1 ~= nil)
    assert(x2 ~= nil)
    assert(y2 ~= nil)

    obj.x1 = x1
    obj.y1 = y1
    obj.x2 = x2
    obj.y2 = y2

    return obj
end

function Vector:dx()
    return self.x2 - self.x1
end

function Vector:dy()
    return self.y2 - self.y1
end

function Vector:sq_length()
    return self:dx() ^ 2 + self:dy() ^ 2
end

function Vector:length()
    return self:sq_length() ^ (1 / 2)
end

function Vector:direction_x()
    local length = self:length()
    return self:dx() / self:length()
end

function Vector:direction_y()
    return self:dy() / self:length()
end

function Vector:direction()
    local length = self:length()
    return { x = self:dx() / length, y = self:dy() / length }
end
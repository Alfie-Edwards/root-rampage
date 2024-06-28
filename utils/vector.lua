Vector = {
    x1 = nil,
    y1 = nil,
    x2 = nil,
    y2 = nil,
}
setup_class(Vector)

function Vector:__init(x1, y1, x2, y2)
    super().__init(self)
    assert(x1 ~= nil)
    assert(y1 ~= nil)
    assert(x2 ~= nil)
    assert(y2 ~= nil)

    self.x1 = x1
    self.y1 = y1
    self.x2 = x2
    self.y2 = y2
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

function Vector:scale_to_length(length)
    local current_length = self:length()

    assert(current_length ~= 0)

    local scale = length / current_length

    self.x1 = self.x1 * scale
    self.x2 = self.x2 * scale
    self.y1 = self.y1 * scale
    self.y2 = self.y2 * scale
end

function Vector:dot(other)
    return self:dx() * other:dx() + self:dy() * other:dy()
end

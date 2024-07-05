BoundingBox = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
}
setup_class(BoundingBox)

function BoundingBox:__init(x1, y1, x2, y2)
    super().__init(self)
    self.x1 = nil_coalesce(x1, 0)
    self.y1 = nil_coalesce(y1, 0)
    self.x2 = nil_coalesce(x2, 0)
    self.y2 = nil_coalesce(y2, 0)
end

function BoundingBox:contains(x, y)
    return (x >= self.x1 and x < self.x2 and y >= self.y1 and y < self.y2)
end

function BoundingBox:width()
    return self.x2 - self.x1
end

function BoundingBox:height()
    return self.y2 - self.y1
end

function BoundingBox:center_x()
    return (self.x2 + self.x1) / 2
end

function BoundingBox:center_y()
    return (self.y2 + self.y1) / 2
end

function BoundingBox:__tostring()
    return "{"..self.x1..", "..self.y1..", "..self.x2..", "..self.y2.."}"
end

function BoundingBox:equals(other)
    return (self.x1 == other.x1 and self.y1 == other.y1 and self.x2 == other.x2 and self.y2 == other.y2)
end

function BoundingBox:reset(other)
    if other == nil then
        self.x1 = 0
        self.y1 = 0
        self.x2 = 0
        self.y2 = 0
    else
        self.x1 = other.x1
        self.y1 = other.y1
        self.x2 = other.x2
        self.y2 = other.y2
    end
end

function BoundingBox:union(other)
    return BoundingBox(
        math.min(self.x1, other.x1),
        math.min(self.y1, other.y1),
        math.max(self.x2, other.x2),
        math.max(self.y2, other.y2)
    )
end

function BoundingBox:intersection(other)
    return BoundingBox(
        math.max(self.x1, other.x1),
        math.max(self.y1, other.y1),
        math.min(self.x2, other.x2),
        math.min(self.y2, other.y2)
    )
end

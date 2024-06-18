BoundingBox = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
}
setup_class(BoundingBox)

function BoundingBox:__init(x1, y1, x2, y2)
    super().__init(self)
    self.x1 = x1
    self.y1 = y1
    self.x2 = x2
    self.y2 = y2
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

BoundingBox = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
}
setup_class(BoundingBox)

function BoundingBox.new(x1, y1, x2, y2)
    local obj = magic_new()
    obj.x1 = x1
    obj.y1 = y1
    obj.x2 = x2
    obj.y2 = y2

    return obj
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
require "ui.element"

Void = {}
setup_class(Void, Element)

function Void:__init(width, height, x, y)
    super().__init(self)

    width = nil_coalesce(width, 0)
    height = nil_coalesce(height, width)
    x = nil_coalesce(x, 0)
    y = nil_coalesce(y, x)
    self.bb = BoundingBox(x, y, x + width, y + height)
end

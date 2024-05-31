require "ui.element"

LayoutElement = {
    x = nil,
    y = nil,
    width = nil,
    height = nil,
    x_align = nil, -- left, center, right
    y_align = nil, -- top, center, bottom
}
setup_class(LayoutElement, Element)

function LayoutElement:__init()
    super().__init(self)
end

function LayoutElement:set_x(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("x", value) then
        self:update_layout()
    end
end

function LayoutElement:set_y(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("y", value) then
        self:update_layout()
    end
end

function LayoutElement:set_width(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("width", value) then
        self:update_layout()
    end
end

function LayoutElement:set_height(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("height", value) then
        self:update_layout()
    end
end

function LayoutElement:set_x_align(value)
    if not value_in(value, {"left", "center", "right", "nil"}) then
        self:_value_error("Valid values are 'left', 'center', 'right', or nil.")
    end
    if self:_set_property("x_align", value) then
        self:update_layout()
    end
end

function LayoutElement:set_y_align(value)
    if not value_in(value, {"top", "center", "bottom", "nil"}) then
        self:_value_error("Valid values are 'top', 'center', 'bottom', or nil.")
    end
    if self:_set_property("y_align", value) then
        self:update_layout()
    end
end

function LayoutElement:update_layout()
    self.bb = calculate_bb(self.x, self.y, self.width, self.height, self.x_align, self.y_align)
end

function calculate_bb(x, y, width, height, x_align, y_align)
    local x1, y1, x2, y2
    x = x or 0
    y = y or 0
    width = width or 0
    height = height or 0
    x_align = x_align or "left"
    y_align = y_align or "top"

    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(width) == "number")
    assert(type(height) == "number")
    assert(value_in(x_align, {"left", "center", "right"}))
    assert(value_in(y_align, {"top", "center", "bottom"}))

    if x_align == "left" then
        x1 = x
        x2 = x + width
    elseif x_align == "center" then
        x1 = x - width / 2
        x2 = x + width / 2
    elseif x_align == "right" then
        x1 = x - width
        x2 = x
    end

    if y_align == "top" then
        y1 = y
        y2 = y + height
    elseif y_align == "center" then
        y1 = y - height / 2
        y2 = y + height / 2
    elseif y_align == "bottom" then
        y1 = y - height
        y2 = y
    end

    return BoundingBox(x1, y1, x2, y2)
end

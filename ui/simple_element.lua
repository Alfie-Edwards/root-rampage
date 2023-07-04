require "ui.element"
require "utils"

SimpleElement = {
    background = nil,
    x = nil,
    y = nil,
    width = nil,
    height = nil,
    x_align = nil, -- left, center, right
    y_align = nil, -- top, center, bottom
}
setup_class(SimpleElement, Element)

function SimpleElement.new()
    local obj = magic_new()

    return obj
end

function SimpleElement:get_background_color()
    return self.background_color
end

function SimpleElement:set_background_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self.background_color = value
end

function SimpleElement:get_x()
    return self.x
end

function SimpleElement:set_x(value)
    if not value_in(type(value), {"number", nil}) then
        self:_value_error("Value must be a number, or nil.")
    end
    if self.x == value then
        return
    end
    self.x = value
    self:update_layout()
end

function SimpleElement:get_y()
    return self.y
end

function SimpleElement:set_y(value)
    if not value_in(type(value), {"number", nil}) then
        self:_value_error("Value must be a number, or nil.")
    end
    if self.y == value then
        return
    end
    self.y = value
    self:update_layout()
end

function SimpleElement:get_width()
    return self.width
end

function SimpleElement:set_width(value)
    if not value_in(type(value), {"number", nil}) then
        self:_value_error("Value must be a number, or nil.")
    end
    if self.width == value then
        return
    end
    self.width = value
    self:update_layout()
end

function SimpleElement:get_height()
    return self.height
end

function SimpleElement:set_height(value)
    if not value_in(type(value), {"number", nil}) then
        self:_value_error("Value must be a number, or nil.")
    end
    if self.height == value then
        return
    end
    self.height = value
    self:update_layout()
end

function SimpleElement:get_x_align()
    return self.x_align
end

function SimpleElement:set_x_align(value)
    if not value_in(value, {"left", "center", "right", nil}) then
        self:_value_error("Valid values are 'left', 'center', 'right', or nil.")
    end
    if self.x_align == value then
        return
    end
    self.x_align = value
    self:update_layout()
end

function SimpleElement:get_y_align()
    return self.y_align
end

function SimpleElement:set_y_align(value)
    if not value_in(value, {"top", "center", "bottom", nil}) then
        self:_value_error("Valid values are 'top', 'center', 'bottom', or nil.")
    end
    if self.y_align == value then
        return
    end
    self.y_align = value
    self:update_layout()
end

function SimpleElement:update_layout()
    self.bb = calculate_bb(self.x, self.y, self.width, self.height, self.x_align, self.y_align)
end

function SimpleElement:draw()
    super().draw(self)

    -- Draw background.
    if self.background_color ~= nil and self.background_color[4] ~= 0 then
        love.graphics.setColor(self.background_color)
        love.graphics.rectangle("fill", 0, 0, self.bb:width(), self.bb:height())
    end
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

    return BoundingBox.new(x1, y1, x2, y2)
end
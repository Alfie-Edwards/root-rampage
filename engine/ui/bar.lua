require "engine.ui.simple_element"
require "utils"

Bar = {
    progress = nil,
    label = nil,
    border_thickness = nil,
    border_color = nil,
    bar_color = nil,
    label_color = nil,
}
setup_class(Bar, SimpleElement)

function Bar.new()
    local obj = magic_new()

    return obj
end

function Bar:set_progress(value)
    if not value_in(type(value), {"number", "nil"}) then
        self:_value_error("Value must be a number, or nil.")
    end
    self:_set_property("progress", value)
end

function Bar:set_label(value)
    if not value_in(type(value), {"string", "nil"}) then
        self:_value_error("Value must be a string, or nil.")
    end
    self:_set_property("label", value)
end

function Bar:set_border_thickness(value)
    if not value_in(type(value), {"number", "nil"}) then
        self:_value_error("Value must be a number, or nil.")
    end
    self:_set_property("border_thickness", value)
end
function Bar:set_border_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("border_color", value)
end

function Bar:set_bar_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("bar_color", value)
end

function Bar:set_label_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("label_color", value)
end

function Bar:draw()
    super().draw(self)

    if self.progress ~= nil and self.bar_color ~= nil then
        local progress = self.progress
        progress = math.max(0, progress)
        progress = math.min(1, progress)
        love.graphics.setColor(self.bar_color)
        love.graphics.rectangle("fill", 0, 0, self.bb:width() * progress, self.bb:height())
    end

    if self.border_thickness ~= nil and self.border_color ~= nil then
        local clamped_border_thickness = math.min(self.border_thickness, (self.height or 0) / 2)
        clamped_border_thickness = math.min(clamped_border_thickness, (self.width or 0) / 2)
        local inset = clamped_border_thickness / 2

        love.graphics.setColor(self.border_color)
        love.graphics.setLineWidth(clamped_border_thickness)
        love.graphics.rectangle("line", inset, inset, self.bb:width() - inset * 2, self.bb:height() - inset * 2)
    end

    if self.label ~= nil and self.label_color ~= nil then
        love.graphics.setColor(self.label_color)
        local margin = (self.border_thickness or 0) + 1
        love.graphics.print(self.label, margin, margin)
    end

end

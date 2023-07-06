require "engine.ui.simple_element"
require "utils"

Drawable = {
    drawable = nil,
}
setup_class(Drawable, SimpleElement)

function Drawable.new()
    local obj = magic_new()

    return obj
end

function Drawable:set_drawable(value)
    if value ~= nil and not value:typeOf("Drawable") then
        self:_value_error("Value must be a love.graphics.Drawable, or nil.")
    end
    if self:_set_property("drawable", value) then
        self:update_layout()
    end
end

function Drawable:update_layout()
    local width = 0
    local height = 0

    if self.drawable ~= nil then
        width = self.drawable:getWidth()
        height = self.drawable:getHeight()
    end

    -- Calculate bounding box.
    if self.width ~= nil then
        width = math.max(width, self.width)
    end
    if self.height ~= nil then
        height = math.max(height, self.height)
    end
    self.bb = calculate_bb(self.x, self.y, width, height, self.x_align, self.y_align)
end

function Drawable:draw()
    super().draw(self)

    if self.drawable ~= nil then
        local bb_width = self.bb:width()
        local bb_height = self.bb:height()
        local drawable_width = self.drawable:getWidth()
        local drawable_height = self.drawable:getHeight()
        love.graphics.push()
        love.graphics.scale(bb_width / drawable_width, bb_height / drawable_height)
        love.graphics.draw(self.drawable)
        love.graphics.pop()
    end
end

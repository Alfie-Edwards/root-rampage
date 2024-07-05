require "ui.layout_element"

Image = {
}
setup_class(Image, LayoutElement)

function Image:__init(image)
    super().__init(self)

    self.pixel_hit_detection = true
    self._image = nil
    self.image = image
end

function Image:set_pixel_hit_detection(value)
    if not is_type(value, "boolean") then
        self:_value_error("Value must be a boolean.")
    end
    self:_set_property("pixel_hit_detection", value)
end

function Image:set_image(value)
    if not is_type(value, "ImageData", "nil") then
        self:_value_error("Value must be a love.image.ImageData, or nil.")
    end

    local old_value = self.image
    if self:_set_property("image", value) then
        self:on_image_change(old_value, value)
        self:update_layout()
    end
end

function Image:on_image_change(old_value, new_value)
    if self._image ~= nil then
        self._image:release()
        self._image = nil
    end
    if new_value ~= nil then
        self._image = love.graphics.newImage(new_value)
    end
end

function Image:update_layout()
    local width = 0
    local height = 0

    if self.image ~= nil then
        width = self.image:getWidth()
        height = self.image:getHeight()
    end

    -- Calculate bounding box.
    if self.width ~= nil then
        width = self.width
    end
    if self.height ~= nil then
        height = self.height
    end
    self.bb = calculate_bb(self.x, self.y, width, height, self.x_align, self.y_align)
end

function Image:draw_image()
    if self._image ~= nil then
        local bb_width = self.bb:width()
        local bb_height = self.bb:height()
        local image_width = self.image:getWidth()
        local image_height = self.image:getHeight()
        love.graphics.scale(bb_width / image_width, bb_height / image_height)
        love.graphics.draw(self._image)
    end
end

function Image:draw()
    super().draw(self)

    love.graphics.push()
    love.graphics.setColor({1, 1, 1, 1})
    self:draw_image()
    love.graphics.pop()
end
 
function Image:contains(x, y)
    if self.pixel_hit_detection == false or self.image == nil then
        -- If we have no image data, fallback to default.
        return Element.contains(self, x, y)
    end

    if not Element.contains(self, x, y) then
        -- Start with a quick bounds check.
        return false
    end

    -- Return false if pixel is transparent.
    local pixel_x = x * self.image:getWidth() / self.bb:width()
    local pixel_y = y * self.image:getHeight() / self.bb:height()
    local _, _, _, alpha = self.image:getPixel(pixel_x, pixel_y)
    return alpha > 0
end

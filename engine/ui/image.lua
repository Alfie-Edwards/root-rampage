require "engine.ui.simple_element"
require "utils"

Image = {
    image_data = nil,
    image = nil,
    pixel_hit_detection = nil,
}
setup_class(Image, SimpleElement)

function Image.new()
    local obj = magic_new()

    obj.pixel_hit_detection = true

    return obj
end

function Image:set_pixel_hit_detection(value)
    if not is_type(value, "boolean") then
        self:_value_error("Value must be a boolean.")
    end
    self:_set_property("pixel_hit_detection", value)
end

function Image:set_image(value)
    if not is_type(value, "Texture", "nil") then
        self:_value_error("Value must be a love.graphics.Texture, a love.graphics.Image, or nil.")
    end
    if self:_set_property("image", value) then
        self:update_layout()
    end
end

function Image:set_image_data(value)
    if not is_type(value, "ImageData", "nil") then
        self:_value_error("Value must be a love.image.ImageData, or nil.")
    end
    if self:_set_property("image_data", value) then
        self:update_layout()
    end
end

function Image:update_layout()
    local width = 0
    local height = 0

    if self.image ~= nil then
        width = self.image:getWidth()
        height = self.image:getHeight()
    elseif self.image_data ~= nil then
        width = self.image_data:getWidth()
        height = self.image_data:getHeight()
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

function Image:draw_image()
    local image = self.image or self._cached_data_image
    if image ~= nil then
        local bb_width = self.bb:width()
        local bb_height = self.bb:height()
        local image_width = image:getWidth()
        local image_height = image:getHeight()
        love.graphics.scale(bb_width / image_width, bb_height / image_height)
        love.graphics.draw(image)
    end
end

function Image:draw()
    super().draw(self)

    love.graphics.push()
    love.graphics.setColor({1, 1, 1, 1})
    self:draw_image()
    love.graphics.pop()
end

function Image:update(dt)
    super().update(self, dt)

    if self.image == nil and self.image_data ~= nil and self._cached_data_image == nil then
            self._cached_data_image = love.graphics.newImage(self.image_data)
    elseif (self.image ~= nil or self.image_data == nil) and self._cached_data_image ~= nil then
        self._cached_data_image:release()
        self._cached_data_image = nil
    end
end

function Image:contains(x, y)
    if self.pixel_hit_detection == false or self.image_data == nil then
        -- If we have no image data, fallback to default.
        return Element.contains(self, x, y)
    end

    if not Element.contains(self, x, y) then
        -- Start with a quick bounds check.
        return false
    end

    -- Return false if pixel is transparent.
    local pixel_x = x * self.image_data:getWidth() / self.bb:width()
    local pixel_y = y * self.image_data:getHeight() / self.bb:height()
    local _, _, _, alpha = self.image_data:getPixel(pixel_x, pixel_y)
    return alpha > 0
end

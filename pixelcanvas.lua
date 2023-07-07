

PixelCanvas = {
    size = nil,
    offset = nil,
    canvas = nil,
}
setup_class(PixelCanvas)

function PixelCanvas.new(size, offset)
    if size == nil then
        size = { 1280, 720 }
    end

    if offset == nil then
        offset = { 0, 0 }
    end

    local obj = magic_new()

    obj.size = { w = size[1], h = size[2] }
    obj.offset = { x = offset[1], y = offset[2] }
    obj.canvas = love.graphics.newCanvas(obj.size.w, obj.size.h)

    return obj
end

function PixelCanvas:width()
    return self.size.w
end

function PixelCanvas:height()
    return self.size.h
end

function PixelCanvas:position()
    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()
    local scale_x = screen_w / self:width()
    local scale_y = screen_h / self:height()
    local scale = math.min(scale_x, scale_y)
    local offset_x = ((screen_w - (self:width() * scale)) / 2) + self.offset.x
    local offset_y = ((screen_h - (self:height() * scale)) / 2) + self.offset.y
    return offset_x, offset_y, scale
end

function PixelCanvas:screen_to_canvas(screen_x, screen_y)
    local x_offset, y_offset, scale = self:position()
    local canvas_x = (screen_x - x_offset) / scale
    local canvas_y = (screen_y - y_offset) / scale
    return {x = canvas_x, y = canvas_y}
end

function PixelCanvas:draw()
    love.graphics.push()
    love.graphics.origin()

    local x_offset, y_offset, scale = self:position()
    love.graphics.setCanvas()
    love.graphics.setColor({1, 1, 1, 1})
    love.graphics.draw(self.canvas, x_offset, y_offset, 0, scale, scale)

    love.graphics.pop()
end

function PixelCanvas:set()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0)
end

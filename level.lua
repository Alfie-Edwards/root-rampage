require "utils"


Level = {
    img = love.graphics.newImage("assets/level-img.png"),

    geom = love.image.newImageData("assets/level-geom.bmp"),
    geom_img = nil,  -- geom as an image, to draw for debugging
}
setup_class("Level")

function Level.new()
    local obj = {}
    setup_instance(obj, Level)

    obj.geom_img = love.graphics.newImage(obj.geom)
    obj.geom_img:setFilter("nearest")

    return obj
end

function Level:cell(x, y)
    local scale_x = self.geom:getWidth() / canvas:width()
    local scale_y = self.geom:getHeight() / canvas:height()

    local cell_x = x * scale_x
    local cell_y = y * scale_y

    return cell_x, cell_y
end

function Level:cell_size()
    return canvas:width() / self.geom:getWidth()
end

function Level:position_in_cell(x, y)
    local cs = self:cell_size()
    return x % cs, y % cs
end

function Level:out_of_bounds(x, y)
    return x < 0 or x > canvas:width() or
           y < 0 or y > canvas:height()
end

function Level:solid(pos)
    if self:out_of_bounds(pos.x, pos.y) then
        return true
    end

    local cell_x, cell_y = self:cell(pos.x, pos.y)

    return self.geom:getPixel(cell_x, cell_y) == 0
end

function Level:is_grow_zone(pos)
    if self:out_of_bounds(pos.x, pos.y) then
        return false
    end
    return pos.x > 200 and pos.y > 200 and pos.x < 300 and pos.y < 300
end

function Level:draw_geom(opacity)
    if opacity == nil then
        opacity = 1
    end

    local scale_x = canvas:width() / self.geom_img:getWidth()
    local scale_y = canvas:height() / self.geom_img:getHeight()

    love.graphics.draw(self.geom_img, 0, 0, 0, scale_x, scale_y)
end

function Level:draw()
    self:draw_geom()
end

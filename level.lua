require "utils"


Level = {
    img = love.graphics.newImage("assets/map3.png"),

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

function Level:cell_x(x)
    local scale_x = self.geom:getWidth() / canvas:width()
    return math.floor(x * scale_x)
end

function Level:cell_y(y)
    local scale_y = self.geom:getHeight() / canvas:height()
    return math.floor(y * scale_y)
end

function Level:cell(x, y)
    return self:cell_x(x), self:cell_y(y)
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

function Level:cell_solid(x, y)
    return self.geom:getPixel(x, y) == 0
end

function Level:solid(pos)
    if self:out_of_bounds(pos.x, pos.y) then
        return true
    end

    local cell_x, cell_y = self:cell(pos.x, pos.y)

    return self:cell_solid(cell_x, cell_y)
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

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.geom_img, 0, 0, 0, scale_x, scale_y)
end

function Level:draw_img()
    local scale_x = canvas:width() / self.img:getWidth()
    local scale_y = canvas:height() / self.img:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.img, 0, 0, 0, scale_x, scale_y)
end

function Level:draw()
    self:draw_img()
end

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
    local scale_x = self.geom_img:getWidth() / canvas:width()
    local scale_y = self.geom_img:getHeight() / canvas:height()

    local cell_x = x * scale_x
    local cell_y = y * scale_y

    return cell_x, cell_y
end

function Level:cell_size()
    return canvas:width() / self.geom_img:getWidth()
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

function Level:collide(pos, vel)
    local next_pos = moved(pos, vel)

    if not self:solid(next_pos) then
        return vel
    end

    local old_cell_x, old_cell_y = self:cell(pos.x, pos.y)
    local new_cell_x, new_cell_y = self:cell(next_pos.x, next_pos.y)

    local intersection_x, intersection_y = self:position_in_cell(next_pos.x, next_pos.y)
    local cs = self:cell_size()

    local adjusted_vel = shallowcopy(vel)

    if old_cell_x ~= new_cell_x then
        if vel.x > 0 then
            -- left edge
            adjusted_vel.x = adjusted_vel.x - intersection_x
        else
            -- right edge
            adjusted_vel.x = adjusted_vel.x + (cs - intersection_x)
        end
    else
        if vel.y > 0 then
            -- top edge
            adjusted_vel.y = adjusted_vel.y - intersection_y
        else
            -- bottom edge
            adjusted_vel.y = adjusted_vel.y + (cs - intersection_y)
        end
    end

    return adjusted_vel
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

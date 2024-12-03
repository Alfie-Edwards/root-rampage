
LEVEL = {
    img = assets:get_image("map3"),

    geom = assets:get_image_data("level-geom", "bmp"),
}

function LEVEL.draw(state, inputs, dt)
    LEVEL.draw_img(level)
end

function LEVEL.draw_img()
    local scale_x = canvas:width() / LEVEL.img:getWidth()
    local scale_y = canvas:height() / LEVEL.img:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(LEVEL.img, 0, 0, 0, scale_x, scale_y)
end

function LEVEL.cell_x(x)
    local scale_x = LEVEL.geom:getWidth() / canvas:width()
    return math.floor(x * scale_x)
end

function LEVEL.cell_y(y)
    local scale_y = LEVEL.geom:getHeight() / canvas:height()
    return math.floor(y * scale_y)
end

function LEVEL.cell(x, y)
    return LEVEL.cell_x(x), LEVEL.cell_y(y)
end

function LEVEL.cell_size()
    return canvas:width() / LEVEL.geom:getWidth()
end

function LEVEL.position_in_cell(x, y)
    local cs = LEVEL.cell_size()
    return x % cs, y % cs
end

function LEVEL.out_of_bounds(x, y)
    return x < 0 or x > canvas:width() or
           y < 0 or y > canvas:height()
end

function LEVEL.cell_solid(x, y)
    if LEVEL.out_of_bounds(x * LEVEL.cell_size(), y * LEVEL.cell_size()) then
        return true
    end
    return LEVEL.geom:getPixel(x, y) == 0
end

function LEVEL.solid(pos)
    local cell_x, cell_y = LEVEL.cell(pos.x, pos.y)

    return LEVEL.cell_solid(cell_x, cell_y)
end

function LEVEL.is_grow_zone(pos)
    if LEVEL.out_of_bounds(pos.x, pos.y) then
        return false
    end
    return pos.x > 200 and pos.y > 200 and pos.x < 300 and pos.y < 300
end

function intersect_rect_circle(rect, circle)
    local half_rect_width = math.abs((rect.x2 - rect.x1) / 2)
    local half_rect_height = math.abs((rect.y2 - rect.y1) / 2)
    local dist_x = math.abs(circle.x - rect.x1 - half_rect_width);
    local dist_y = math.abs(circle.y - rect.y1 - half_rect_height);

    if dist_x > (half_rect_width + circle.r) or dist_y > (half_rect_height + circle.r) then
        return false
    end
    if dist_x <= half_rect_width or dist_y <= half_rect_height then
        return true
    end
    return sq_dist(half_rect_width, half_rect_height, dist_x, dist_y) < (circle.r ^ 2);
end
Cell = {
    x = nil,
    y = nil,
}
setup_class(Cell)

function Cell:__init(x, y)
    super().__init(self)

    self.x = math.floor(x)
    self.y = math.floor(y)
end

function Cell:__eq(other)
    if not is_type(other, Cell) then
        return false
    end
    return self:__hash() == other:__hash()
end

function Cell:__tostring()
    return "Cell("..tostring(self.x)..", "..tostring(self.y)..")"
end

function Cell:__hash()
    return tostring(self.x)..","..tostring(self.y)
end

function raycast(x, y, angle, fov, max_distance, valid_cells)
    local result = HashSet()
    local start_cell = Cell(x, y)
    local angle_start = angle - fov / 2
    local angle_end = angle - fov / 2
    local arc_length = max_distance * fov
    local rays = math.max(2, math.ceil(arc_length))
    local d_angle = 0
    local inc = max_distance / (2 * math.ceil(max_distance))
    for i=1,rays do
        local ray_x = x
        local ray_y = y
        local ray_angle = angle_start + ((i - 1) * fov) / (rays - 1)
        local dx = math.cos(ray_angle)
        local dy = math.sin(ray_angle)
        for distance = 0, max_distance, inc do
            local cell = Cell(x + dx * distance, y + dy * distance)
            if not valid_cells:contains(cell) then
                if cell ~= start_cell then
                    break
                end
            else
                result:add(cell)
            end
        end
    end

    return result
end

function line_super_cover(x1, y1, x2, y2)
    local result = HashSet()
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)

    local x = math.floor(x1)
    local y = math.floor(y1)

    local n = 1
    local x_inc, y_inc
    local error

    if dx == 0 then
        x_inc = 0
        error = math.huge
    elseif x2 > x1 then
        x_inc = 1
        n = n + math.floor(x2) - x
        error = (math.floor(x1) + 1 - x1) * dy
    else
        x_inc = -1
        n = n + x - math.floor(x2)
        error = (x1 - math.floor(x1)) * dy
    end

    if dy == 0 then
        y_inc = 0
        error = error - math.huge
    elseif y2 > y1 then
        y_inc = 1
        n = n + math.floor(y2) - y
        error = error - (math.floor(y1) + 1 - y1) * dx
    else
        y_inc = -1
        n = n + y - math.floor(y2)
        error = error - (y1 - math.floor(y1)) * dx
    end

    while n > 0 do
        result:add(Cell(x, y))

        if (error > 0) then
            y = y + y_inc
            error = error - dx
        else
            x = x + x_inc
            error = error + dy
        end
        n = n - 1
    end

    return result
end

function floodfill(x, y, all_cells, match_fn)
    local result = HashSet()
    local cell = Cell(x, y)

    if not all_cells[cell] or not match_fn(cell) then
        return result
    end

    local open_cells = HashSet(cell)
    local closed_cells = HashSet()
    while cell ~= nil do
        result:add(cell)
        closed_cells:add(cell)
        open_cells:remove(cell)

        for _, neighbor in ipairs({ Cell(cell.x - 1, cell.y),
                                    Cell(cell.x, cell.y - 1),
                                    Cell(cell.x + 1, cell.y),
                                    Cell(cell.x, cell.y + 1) }) do
            if all_cells[neighbor] and (not closed_cells[neighbor]) and (not open_cells[neighbor]) and match_fn(neighbor) then
                open_cells:add(neighbor)
            end
        end
        cell, _ = first_pair(open_cells)
    end

    return result
end

function cell_rect(x1, y1, x2, y2)
    local result  = HashSet()
    for cell_y = y1, y2 do
        for cell_x = x1, x2 do
            result:add(Cell(cell_x, cell_y))
        end
    end
    return result
end

function cell_circle(x, y, r)
    local result = HashSet()

    for cell, _ in pairs(cell_rect(math.floor(x - r), math.floor(y - r), math.floor(x + r), math.floor(y + r))) do
        if intersect_rect_circle({ x1 = cell.x, y1 = cell.y, x2 = cell.x + 1, y2 = cell.y + 1 }, {x = x, y = y, r = r}) then
            result:add(cell)
        end
    end

    return result
end

SpatialTable = {
    bb = nil,
    regions = nil,
    len = nil,
}
setup_class(SpatialTable)

function SpatialTable:__init(x1, y1, x2, y2, cell_size)
    super().__init(self)
    self.cell_size = cell_size
    self.bb = BoundingBox(x1, y1, x2, y2)
    self.regions = HashMap()
    self.len = 0
end

function SpatialTable:add(x, y, obj)
    assert(self.bb:contains(x, y))
    local cx = math.floor((x - self.bb.x1) / self.cell_size)
    local cy = math.floor((y - self.bb.y1) / self.cell_size)

    if not self.regions:contains_key(Cell(cx, cy)) then
        self.regions[Cell(cx, cy)] = {}
    end
    table.insert(self.regions[Cell(cx, cy)], SpatialTableItem(x, y, obj))
    self.len = self.len + 1
end

function SpatialTable:remove(x, y, obj)
    assert(self.bb:contains(x, y))
    local cx = math.floor((x - self.bb.x1) / self.cell_size)
    local cy = math.floor((y - self.bb.y1) / self.cell_size)

    local region = self.regions[Cell(cx, cy)]
    if region == nil then
        return
    end

    for i = 1, #region do
        if region[i].obj == obj then
            table.remove(region, i)
            self.len = self.len - 1
            if #region == 0 then
                self.regions[Cell(cx, cy)] = nil
            end
            return
        end
    end
end

function SpatialTable:any()
    return self.len > 0
end

function SpatialTable:any_in_radius(x, y, r)
    assert(self.bb:contains(x, y))

    local r_sq = r * r
    local result = {}

    local cx = (math.floor(x - self.bb.x1) / self.cell_size)
    local cy = math.floor((y - self.bb.y1) / self.cell_size)
    local cr = math.ceil(r / self.cell_size)
    for ci = cx - cr, cx + cr do
        for cj = cy - cr, cy + cr do
            local region = self.regions[Cell(cx, cy)]
            if region ~= nil then
                for _, item in ipairs(region) do
                    if sq_dist(x, y, item.x, item.y) <= r_sq then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function SpatialTable:in_radius(x, y, r)
    assert(self.bb:contains(x, y))

    local r_sq = r * r
    local result = {}

    local cx = math.floor((x - self.bb.x1) / self.cell_size)
    local cy = math.floor((y - self.bb.y1) / self.cell_size)
    local cr = math.ceil(r / self.cell_size)
    for ci = cx - cr, cx + cr do
        for cj = cy - cr, cy + cr do
            local region = self.regions[Cell(cx, cy)]
            if region ~= nil then
                for _, item in ipairs(region) do
                    if sq_dist(x, y, item.x, item.y) <= r_sq then
                        table.insert(result, item.obj)
                    end
                end
            end
        end
    end
    return result
end

function SpatialTable:closest(x, y)
    assert(self.bb:contains(x, y))

    local closest = nil
    local closest_dist = 1e99

    local queue = PriorityQueue()
    local seen = HashSet()

    local check = function(cell)
        local region = self.regions[cell]
        if region ~= nil then
            for _, item in ipairs(region) do
                local dist = sq_dist(x, y, item.x, item.y)
                if dist < closest_dist then
                    closest = item.obj
                    closest_dist = dist
                end
            end
        end
    end

    local cw = math.ceil(self.bb:width() / self.cell_size)
    local ch = math.ceil(self.bb:height() / self.cell_size)
    local enqueue = function(cx, cy)
        if seen:contains(Cell(cx, cy)) or (cx < 0) or (cy < 0) or (cx > cw) or (cy > ch) then
            return
        end
        seen:add(Cell(cx, cy))

        local middle_x = (cx + 0.5) * self.cell_size + self.bb.x1
        local middle_y = (cy + 0.5) * self.cell_size + self.bb.y1
        queue:enqueue(Cell(cx, cy), sq_dist(x, y, middle_x, middle_y))
    end

    enqueue((x - self.bb.x1) / self.cell_size, (y - self.bb.y1) / self.cell_size)

    while not queue:empty() do
        cell, dist = queue:dequeue()

        if dist > (closest_dist + self.cell_size * self.cell_size) then
            break
        end

        -- Enqueue neighbors.
        enqueue(cell.x - 1, cell.y)
        enqueue(cell.x + 1, cell.y)
        enqueue(cell.x, cell.y - 1)
        enqueue(cell.x, cell.y + 1)

        check(cell)
    end

    return closest
end

SpatialTableItem = {
    obj = nil,
    x = nil,
    y = nil,
}
setup_class(SpatialTableItem)

function SpatialTableItem:__init(x, y, obj)
    super().__init(self)
    self.x = x
    self.y = y
    self.obj = obj
end

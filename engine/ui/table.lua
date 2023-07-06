require "engine.ui.simple_element"
require "utils"

Table = {
    cols = nil,
    rows = nil,
    cells = nil,
    column_widths = nil,
    row_heights = nil,
}
setup_class(Table, SimpleElement)

function Table.new()
    local obj = magic_new()

    obj.cells = {}

    return obj
end

function Table:set_cols(value)
    if not (value == nil or is_positive_integer(value)) then
        self:_value_error("Value must be a positive integer, or nil.")
    end
    if self:_set_property("cols", value) then
        self:update_layout()
    end
end

function Table:set_rows(value)
    if not (value == nil or is_positive_integer(value)) then
        self:_value_error("Value must be a positive integer, or nil.")
    end
    if self:_set_property("rows", value) then
        self:update_layout()
    end
end

function Table:cell(col, row)
    assert(is_positive_integer(col))
    assert(is_positive_integer(row))
    local key = tostring(col)..","..tostring(row)

    if self.cells[key] == nil then
        self.cells[key] = SimpleElement.new()
    end

    return self.cells[key]
end

function Table:set_column_widths(value)
    if not value_in(type_string(value), {"table", nil}) then
        self:_value_error("Value must be a table of {positive integer -> number}, or nil.")
    end
    if value ~= nil then
        for col, size in pairs(value) do
            if not (is_positive_integer(col) and type_string(size) == "number") then
                self:_value_error("Value must be a table of {positive integer -> number}, or nil.")
            end
        end
    end
    if self:_set_property("col_widths", value) then
        self:update_layout()
    end
end

function Table:set_row_heights(value)
    if not value_in(type_string(value), {"table", nil}) then
        self:_value_error("Value must be a table of {positive integer -> number}, or nil.")
    end
    if value ~= nil then
        for row, size in pairs(value) do
            if not (is_positive_integer(row) and type_string(size) == "number") then
                self:_value_error("Value must be a table of {positive integer -> number}, or nil.")
            end
        end
    end
    if self:_set_property("row_heights", value) then
        self:update_layout()
    end
end

function Table:get_column_width(col)
    assert(is_positive_integer(col))

    if self.column_widths == nil then
        return 1
    end
    if self.column_widths[col] == nil then
        return 1
    end
    return self.column_widths[col]
end

function Table:get_row_height(row)
    assert(is_positive_integer(row))

    if self.row_heights == nil then
        return 1
    end
    if self.row_heights[row] == nil then
        return 1
    end
    return self.row_heights[row]
end

function Table:update_layout()
    super().update_layout(self)

    self:clear_children()

    local cols = self.cols or 1
    local rows = self.rows or 1
    local total_col_width = 0
    local total_row_height = 0

    for col=1, cols do
        total_col_width = total_col_width + self:get_column_width(col)
    end
    for row=1, rows do
        total_row_height = total_row_height + self:get_row_height(row)
    end

    -- Avoid divide by zero.
    if total_col_width == 0 then
        total_col_width = 1
    end
    if total_row_height == 0 then
        total_row_height = 1
    end

    local y = 0
    for row=1, rows do
        local height = self.bb:height() * self:get_row_height(row) / total_row_height
        local x = 0
        for col=1, cols do
            local width = self.bb:width() * self:get_column_width(col) / total_col_width

            local cell = self:cell(col, row)
            cell.x = x
            cell.y = y
            cell.width = width
            cell.height = height
            self:add_child(cell)

            x = x + width
        end
        y = y + height
    end
end

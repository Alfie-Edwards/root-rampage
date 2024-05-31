require "ui.layout_element"
require "ui.containers.grid_cell"

GridBox = {
    cols = nil,
    rows = nil,
    cells = nil,
    cell_margin = nil,
    outer_margin = nil,
    column_widths = nil,
    row_heights = nil,
}
setup_class(GridBox, LayoutElement)

function GridBox:__init()
    super().__init(self)

    self.cells = HashMap()
end

function GridBox:get_cols()
    return nil_coalesce(self:_get_property("cols"), 1)
end

function GridBox:set_cols(value)
    if not (value == nil or is_positive_integer(value, true)) then
        self:_value_error("Value must be a positive integer, or nil.")
    end
    if self:_set_property("cols", value) then
        self:update_layout()
    end
end

function GridBox:get_rows()
    return nil_coalesce(self:_get_property("rows"), 1)
end

function GridBox:set_rows(value)
    if not (value == nil or is_positive_integer(value, true)) then
        self:_value_error("Value must be a positive integer, or nil.")
    end
    if self:_set_property("rows", value) then
        self:update_layout()
    end
end

function GridBox:cell(col, row)
    assert(is_positive_integer(col))
    assert(is_positive_integer(row))

    if self.cells:contains_key(Cell(col, row)) then
        return self.cells[Cell(col, row)]
    end

    local cell = GridCell(col, row)
    self.cells[Cell(col, row)] = cell
    return cell
end

function GridBox:set_column_widths(value)
    if not is_type(value, "table", "nil") then
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

function GridBox:set_row_heights(value)
    if not is_type(value, "table", "nil") then
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

function GridBox:get_cell_margin()
    return nil_coalesce(self:_get_property("cell_margin"), 0)
end

function GridBox:set_cell_margin(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("cell_margin", value) then
        self:update_layout()
    end
end

function GridBox:get_outer_margin()
    return nil_coalesce(self:_get_property("outer_margin"), 0)
end

function GridBox:set_outer_margin(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("outer_margin", value) then
        self:update_layout()
    end
end

function GridBox:get_column_width(col)
    assert(is_positive_integer(col))

    if self.column_widths == nil then
        return 1
    end
    if self.column_widths[col] == nil then
        return 1
    end
    return self.column_widths[col]
end

function GridBox:get_row_height(row)
    assert(is_positive_integer(row))

    if self.row_heights == nil then
        return 1
    end
    if self.row_heights[row] == nil then
        return 1
    end
    return self.row_heights[row]
end

function GridBox:update_layout()
    super().update_layout(self)

    self:_clear_visual_children()

    local height_minus_margins = self.bb:height() - self.cell_margin * (self.rows - 1)
    local width_minus_margins = self.bb:width() - self.cell_margin * (self.cols - 1)

    local total_col_width = 0
    local total_row_height = 0
    for col=1, self.cols do
        total_col_width = total_col_width + self:get_column_width(col)
    end
    for row=1, self.rows do
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
    for row=1, self.rows do
        local height = height_minus_margins * (self:get_row_height(row) / total_row_height)

        local x = 0
        for col=1, self.cols do
            local width = width_minus_margins * (self:get_column_width(col) / total_col_width)

            local cell = self:cell(col, row)
            cell.bb = BoundingBox(x, y, x + width, y + height)
            self:_add_visual_child(cell)

            x = x + width + self.cell_margin
        end

        y = y + height + self.cell_margin
    end
end

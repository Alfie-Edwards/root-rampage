require "ui.containers.box"

GridCell = {
    -- col and row are readonly, specified on construction.
    row = nil,
    col = nil,
}
setup_class(GridCell, Box)

function GridCell:__init(col, row)
    super().__init(self)

    if not is_positive_integer(col) then
        self:_value_error("Value must be a positive integer.", "col", col)
    end
    if not is_positive_integer(row) then
        self:_value_error("Value must be a positive integer.", "row", row)
    end

    self:_set_property("col", value)
    self:_set_property("row", value)
end

function GridCell:get_row()
    return self:_get_property("row")
end

function GridCell:get_col()
    return self:_get_property("col")
end

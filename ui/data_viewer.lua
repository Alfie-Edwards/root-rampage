require "ui.layout_element"
require "ui.text"
require "ui.containers.grid_box"

DataViewer = {
    data = nil,
    schema = nil,
    font = nil,
    text_color = nil,
    data_changed_handler = nil,
}

setup_class(DataViewer, LayoutElement)

function DataViewer:__init()
    super().__init(self)

    self.data_changed_handler = function(data, property_name, old_value, new_value)
        if data ~= self.data then
            return
        end
        self:update_layout()
    end

    self.grid = GridBox()
    self.grid.width = OneWayBinding(self, "width")

    self:_add_visual_child(self.grid)

    self:forward_property(self.grid, "cell_margin")

    self.property_changed:subscribe(
        function(element, property_name, old_value, new_value)
            if element ~= self then
                return
            end
            if property_name == "cell_margin" then
                self:update_layout()
            end
        end
    )
end

function DataViewer:get_rows()
    return self.grid.rows
end

function DataViewer:get_cols()
    return self.grid.cols
end

function DataViewer:set_row_height(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("row_height", value) then
        self:update_layout()
    end
end

function DataViewer:set_data(value)
    if self.data ~= value then
        if self.data ~= nil and self.data.property_changed ~= nil then
            self.data.property_changed:unsubscribe(self.data_changed_handler)
        end
        if value ~= nil and value.property_changed ~= nil then
            value.property_changed:subscribe(self.data_changed_handler)
        end
    end
    if self:_set_property("data", value) then
        self:update_layout()
    end
end

function DataViewer:set_schema(value)
    if value ~= nil then
        value = Schema(value)
    end
    if not is_type(value, BaseSchema, "nil")  then
        self:_value_error("Value must be a BaseSchema, or nil.")
    end
    if self:_set_property("schema", value) then
        self:update_layout()
    end
end

function DataViewer:set_font(value)
    if not is_type(value, "Font", "nil")  then
        self:_value_error("Value must be a love.graphics.Font, or nil.")
    end
    if self:_set_property("font", value) then
        self:update_layout()
    end
end

function DataViewer:set_text_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("text_color", value)
end

function DataViewer:update_layout()
    local height = math.max(
        self.height or 0,
        (self.row_height or 0) * self.rows + self.cell_margin * (self.rows + 1))
    self.grid.height = height - (2 * self.cell_margin)
    self.grid.x = self.cell_margin
    self.grid.y = self.cell_margin
    self.bb = calculate_bb(self.x, self.y, self.width, height, self.x_align, self.y_align)

    if self.schema == nil then
        if type(self.data) == "table" then
            local keys = keys_to_sorted_list(self.data)
            self.grid.cols = 2
            self.grid.rows = #keys
            for i, k in ipairs(keys) do
                self:populate(1, i, k)
                self:populate(2, i, self.data[k], nil)
            end
        else
            self.grid.cols = 1
            self.grid.rows = 1
            self:populate(1, 1, self.data, nil)
        end
    else
        if is_type(self.schema, TableSchema) then
            local keys = keys_to_sorted_list(self.schema.t)
            self.grid.cols = 2
            if type(self.data) == "table" then
                self.grid.rows = #keys
                for i, k in ipairs(keys) do
                    self:populate(1, i, k)
                    self:populate(2, i, self.data[k], self.schema.t[k])
                end
            else
                self.grid.rows = nil
            end
        elseif is_type(self.schema, ListSchema) then
            self.grid.cols = 2
            if type(self.data) == "table" then
                self.grid.rows = #(self.data)
                for i, v in ipairs(self.data) do
                    self:populate(1, i, i)
                    self:populate(2, i, v, self.schema.item_schema)
                end
            else
                self.grid.rows = nil
            end
        elseif is_type(self.schema, MapSchema) then
            local keys = keys_to_sorted_list(self.data)
            self.grid.cols = 2
            if type(self.data) == "table" then
                self.grid.rows = #keys
                for i, k in ipairs(keys) do
                    self:populate(1, i, k, self.schema.key_schema)
                    self:populate(2, i, self.data[k], self.schema.value_schema)
                end
            else
                self.grid.rows = nil
            end
        else
            self.grid.cols = 1
            self.grid.rows = 1
            self:populate(1, 1, self.data, self.schema)
        end
    end
end

function DataViewer:populate(col, row, data, schema)
    self.grid:cell(col, row):clear()
    self.grid:cell(col, row):add(self:create_view(data, schema))
end

function DataViewer:create_view(x, schema)
    local label = Text(details_string(x))
    label.font = OneWayBinding(self, "font")
    label.color = OneWayBinding(self, "text_color")
    return label
end
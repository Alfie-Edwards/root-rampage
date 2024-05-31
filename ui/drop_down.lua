require "ui.layout_element"
require "ui.text"
require "ui.containers.grid_box"

DropDown = {
    font = nil,
    text_color = nil,
    value = nil,
    options = nil,
    button_width = nil,
    is_open = nil,
}

setup_class(DropDown, LayoutElement)

function DropDown:__init()
    super().__init(self)

    self.data_changed_handler = function(data, property_name, old_value, new_value)
        if data ~= self.data then
            return
        end
        self:update_layout()
    end

    self.is_open = false

    self.text = Text()
    self.text.text = OneWayBinding(
        self, "value", 
        function(x)
            return details_string(x)
        end
    )
    self.button = Text()
    self.button.text = v
    self.list = FlowBox()
    self.list.orientation = Orientation.DOWN_RIGHT
    self.list.width = OneWayBinding(self, "width")

    self:forward_property(self.text, "color", nil, "text_color")
    self:forward_property(self.list, "items", nil, "options")
    self:forward_property(self.text, "font")

    self:_add_visual_child(self.text)
end

function DropDown:open()
    if self.is_open then
        return
    end
    self.is_open = true
    self:_add_visual_child(self.list)
    self:update_layout()
end

function DropDown:close()
    if not self.is_open then
        return
    end
    self.is_open = false
    self:_remove_visual_child(self.list)
    self:update_layout()
end

function DropDown:set_button_width(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("button_width", value) then
        self:update_layout()
    end
end

function DropDown:set_value(value)
    self:_set_property("value", value)
end

function DropDown:update_layout()
    local height = self.height
    if self.is_open then
        height = height + self.list.bb:height()
    end
    self.bb = calculate_bb(self.x, self.y, self.width, height, self.x_align, self.y_align)
end

function DropDown:populate(col, row, data, schema)
    self.grid:cell(col, row):clear()
    self.grid:cell(col, row):add(self:create_view(data, schema))
end

function DropDown:create_view(x, schema)
    local label = Text(details_string(x))
    label.font = OneWayBinding(self, "font")
    label.color = OneWayBinding(self, "text_color")
    return label
end
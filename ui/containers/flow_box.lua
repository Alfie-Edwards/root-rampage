require "ui.layout_element"

FlowBox = {
    items = nil,
    max_width = nil,
    max_height = nil,
    orientation = nil,
    item_margin = nil,
    line_margin = nil,
    line_height = nil,
    item_changed_handler = nil,
    items_changed_handler = nil,
}
setup_class(FlowBox, LayoutElement)

function FlowBox:__init()
    super().__init(self)

    self.item_changed_handler = function(item, property_name, old_value, new_value)
        if property_name == "bb" then
            self:update_layout()
        end
    end
    self.items_changed_handler = function(items, i, old_value, new_value)
        if old_value ~= nil then
            old_value.property_changed:unsubscribe(self.item_changed_handler)
        end
        if new_value ~= nil then
            new_value.property_changed:subscribe(self.item_changed_handler)
        end
        self:update_layout()
    end

    self.items = PropertyTable()
end

function FlowBox:set_items(value)
    if not (value == nil or value.property_changed ~= nil) then
        self:_value_error("Value must implement a property_changed event (dst, property_name, old_value, new_value), or be nil.")
    end
    local prev_value = self.items
    if self:_set_property("items", value) then
        if prev_value ~= nil then
            prev_value.property_changed:unsubscribe(self.items_changed_handler)
        end
        if value ~= nil then
            value.property_changed:subscribe(self.items_changed_handler)
        end
        self:update_layout()
    end
end

function FlowBox:append(element)
    self.items[iter_size(self.items) + 1] = element
end

function FlowBox:clear(element)
    self.items = PropertyTable()
end

function LayoutElement:set_max_width(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("max_width", value) then
        self:update_layout()
    end
end

function LayoutElement:set_max_height(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("max_height", value) then
        self:update_layout()
    end
end

function FlowBox:get_item_margin()
    return nil_coalesce(self:_get_property("item_margin"), 0)
end

function FlowBox:set_item_margin(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("item_margin", value) then
        self:update_layout()
    end
end

function FlowBox:get_line_margin()
    return nil_coalesce(self:_get_property("line_margin"), 0)
end

function FlowBox:set_line_margin(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("line_margin", value) then
        self:update_layout()
    end
end

function FlowBox:set_line_height(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("line_height", value) then
        self:update_layout()
    end
end

function FlowBox:get_orientation()
    return nil_coalesce(self:_get_property("orientation"), Orientation.RIGHT_DOWN)
end

function FlowBox:set_orientation(value)
    if not (value == nil or Orientation:is(value)) then
        self:_value_error("Value must be a orientation "..tostring(Orientation)..", or nil")
    end
    if self:_set_property("orientation", value) then
        self:update_layout()
    end
end

function FlowBox:update_layout()
    self:_clear_visual_children()

    if self.items == nil then
        return
    end

    local wrap_size = self.max_width
    if primary_axis(self.orientation) == Axis.Y then
        wrap_size = self.max_height
    end
    local flow_direction = primary_direction(self.orientation)
    local wrap_direction = secondary_direction(self.orientation)

    local line_length = 0
    local max_line_length = 0
    local auto_line_height = 0
    local wrap_offset = 0
    local deferred_layouts = {}

    local i = 1
    local i_line_start = i
    while self.items[i] do
        local item = self.items[i]

        local item_length, item_height
        if primary_axis(self.orientation) == Axis.X then
            item_length = item.bb:width()
            item_height = item.bb:height()
        else
            item_length = item.bb:height()
            item_height = item.bb:width()
        end

        if i_line_start ~= i then
            if (wrap_size ~= nil) and (line_length + self.item_margin + item_length) > wrap_size then
                -- Wrap to the next line.
                wrap_offset = wrap_offset + (self.line_height or auto_line_height) + self.line_margin
                max_line_length = math.max(max_line_length, line_length)
                line_length = 0
                auto_line_height = 0
                i_line_start = i
            else
                -- Add item spacing.
                line_length = line_length + self.item_margin
            end
        end
        if self.line_height == nil then
            auto_line_height = math.max(auto_line_height, item_height)
        end

        table.insert(deferred_layouts, {
            -- Captures.
            item_length = item_length,
            item_height = item_height,
            line_length = line_length,
            wrap_offset = wrap_offset,
            init = function(
                    container_width,
                    container_height,
                    item_length,
                    item_height,
                    line_length,
                    wrap_offset)
                local x1, y1, x2, y2
                if flow_direction == Direction.RIGHT then
                    x1 = line_length
                    x2 = line_length + item_length
                elseif flow_direction == Direction.DOWN then
                    y1 = line_length
                    y2 = line_length + item_length
                elseif flow_direction == Direction.LEFT then
                    x1 = container_width - line_length - item_length
                    x2 = container_width - line_length
                elseif flow_direction == Direction.UP then
                    y1 = container_height - line_length - item_length
                    y2 = container_height - line_length
                end
                if wrap_direction == Direction.RIGHT then
                    x1 = wrap_offset
                    x2 = wrap_offset + item_height
                elseif wrap_direction == Direction.DOWN then
                    y1 = wrap_offset
                    y2 = wrap_offset + item_height
                elseif wrap_direction == Direction.LEFT then
                    x1 = container_width - wrap_offset - item_height
                    x2 = container_width - wrap_offset
                elseif wrap_direction == Direction.UP then
                    y1 = container_height - wrap_offset - item_height
                    y2 = container_height - wrap_offset
                end
                local cell = Element()
                cell.bb = BoundingBox(x1, y1, x2, y2)
                cell:_add_visual_child(item)
                self:_add_visual_child(cell)
            end
        })

        line_length = line_length + item_length
        i = i + 1
    end
    max_line_length = math.max(max_line_length, line_length)

    -- Calculate any dynamic dimensions.
    local width = self.width or 0
    local height = self.height or 0
    if primary_axis(self.orientation) == Axis.X then
        width = math.max(width, max_line_length)
        height = math.max(height, wrap_offset + (self.line_height or auto_line_height))
    else
        width = math.max(width, wrap_offset + (self.line_height or auto_line_height))
        height = math.max(height, max_line_length)
    end

    self.bb = calculate_bb(self.x, self.y, width, height, self.x_align, self.y_align)

    for _, layout in ipairs(deferred_layouts) do
        layout.init(width, height, layout.item_length, layout.item_height, layout.line_length, layout.wrap_offset)
    end
end

require "ui.element"
require "ui.containers.frame"

ScrollFrame = {
    frame = nil,
    _content_bb_changed_handler = nil,

    content = nil,
    content_margin = nil,
    scrollbar_thickness = nil,
    scrollbar_margin = nil,
    v_scroll = nil,
    h_scroll = nil,
    scroll_speed = nil,
    scroll_with_mouse = nil,
    show_v_scrollbar = nil,
    show_h_scrollbar = nil,
}
setup_class(ScrollFrame, LayoutElement)

function ScrollFrame:__init()
    super().__init(self)

    self._content_bb_changed_handler = function(content, property_name, prev_value, new_value)
        if content == self.content and property_name == "bb" then
            self:update_scroll()
        end
    end

    self.frame = Frame()
    self:forward_property(self.frame, "content")
    self.frame.property_changed:subscribe(
        function(frame, property_name, prev_value, new_value)
            if frame ~= self.frame or property_name ~= "content" then
                return
            end
            if prev_value ~= nil then
                prev_value.property_changed:unsubscribe(self._content_bb_changed_handler)
            end
            if new_value ~= nil then
                new_value.property_changed:subscribe(self._content_bb_changed_handler)
            end
            self:update_scroll()
        end
    )

    self.wheelmoved = function(self, x, y)
        if not self.scroll_with_mouse then
            return false
        end

        if self.scroll_speed ~= nil then
            x = self.scroll_speed * x
            y = self.scroll_speed * y
        end
        self.v_scroll = clamp((self.v_scroll or 0) + y, 0, self:get_max_v_scroll())
        self.h_scroll = clamp((self.h_scroll or 0) + x, 0, self:get_max_h_scroll())

        return true
    end

    self.v_scrollbar = LayoutElement()
    self.v_scrollbar.background_color = {0, 0, 0, 1}

    self.v_scrollbar.handle = LayoutElement()
    self.v_scrollbar.handle.background_color = {1, 1, 1, 1}

    self.h_scrollbar = LayoutElement()
    self.h_scrollbar.background_color = {0, 0, 0, 1}

    self.h_scrollbar.handle = LayoutElement()
    self.h_scrollbar.handle.background_color = {1, 1, 1, 1}

    self.v_scrollbar:_add_visual_child(self.v_scrollbar.handle)
    self.h_scrollbar:_add_visual_child(self.h_scrollbar.handle)
    self:_add_visual_child(self.frame)

    self:update_scroll()
end

function ScrollFrame:get_content_width()
    if self.content == nil then
        return 0
    end
    return math.max(0, self.content.bb.x2)
end

function ScrollFrame:get_content_height()
    if self.content == nil then
        return 0
    end
    return math.max(0, self.content.bb.y2)
end

function ScrollFrame:get_content_margin()
    return nil_coalesce(self:_get_property("content_margin"), 0)
end

function ScrollFrame:set_content_margin(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("content_margin", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_scrollbar_thickness()
    return nil_coalesce(self:_get_property("scrollbar_thickness"), 0)
end

function ScrollFrame:set_scrollbar_thickness(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("scrollbar_thickness", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_scrollbar_margin()
    return nil_coalesce(self:_get_property("scrollbar_margin"), 0)
end

function ScrollFrame:set_scrollbar_margin(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("scrollbar_margin", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_scrollbar_margin()
    return nil_coalesce(self:_get_property("scroll_speed"), 1)
end

function ScrollFrame:set_scroll_speed(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("scroll_speed", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_v_scroll()
    return nil_coalesce(self:_get_property("v_scroll"), 0)
end

function ScrollFrame:set_v_scroll(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("v_scroll", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_h_scroll()
    return nil_coalesce(self:_get_property("h_scroll"), 0)
end

function ScrollFrame:set_h_scroll(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("h_scroll", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_scroll_with_mouse()
    return nil_coalesce(self:_get_property("scroll_with_mouse"), true)
end

function ScrollFrame:set_scroll_with_mouse(value)
    if not is_type(value, "boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    if self:_set_property("scroll_with_mouse", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_show_v_scrollbar()
    local value = self:_get_property("show_v_scrollbar")
    if value ~= nil then
        return value
    end

    if self.content == nil then
        return false
    end

    local show_h_scrollbar = nil_coalesce(
        self:_get_property("show_h_scrollbar"),
        self.content_width + self:h_non_content_space(false) > self.bb:width()
    )
    return self.content_height + self:v_non_content_space(show_h_scrollbar) > self.bb:height()
end

function ScrollFrame:set_show_v_scrollbar(value)
    if not is_type(value, "boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    if self:_set_property("show_v_scrollbar", value) then
        self:update_scroll()
    end
end

function ScrollFrame:get_show_h_scrollbar()
    local value = self:_get_property("show_h_scrollbar")
    if value ~= nil then
        return value
    end

    if self.content == nil then
        return false
    end

    local show_v_scrollbar = nil_coalesce(
        self:_get_property("show_v_scrollbar"),
        self.content_height + self:v_non_content_space(false) > self.bb:height()
    )

    return self.content_width + self:h_non_content_space(show_v_scrollbar) > self.bb:width()
end

function ScrollFrame:set_show_h_scrollbar(value)
    if not is_type(value, "boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    if self:_set_property("show_h_scrollbar", value) then
        self:update_scroll()
    end
end

function ScrollFrame:v_non_content_space(show_h_scrollbar)
    if show_h_scrollbar == false or (show_h_scrollbar == nil and self.show_h_scrollbar == false) then
        return (2 * self.content_margin)
    end

    if self:_get_property("content_margin") == nil then
        return self.content_margin + self.scrollbar_thickness + (2 * self.scrollbar_margin)
    end

    return (2 * self.content_margin) + self.scrollbar_thickness + self.scrollbar_margin
end

function ScrollFrame:h_non_content_space(show_v_scrollbar)
    if show_v_scrollbar == false or (show_v_scrollbar == nil and self.show_v_scrollbar == false) then
        return (2 * self.content_margin)
    end

    if self:_get_property("content_margin") == nil then
        return self.content_margin + self.scrollbar_thickness + (2 * self.scrollbar_margin)
    end

    return (2 * self.content_margin) + self.scrollbar_thickness + self.scrollbar_margin
end

function ScrollFrame:get_max_v_scroll()
    if self.show_h_scrollbar then
        return math.max(0, self.content_height + (2 * self.content_margin) + self.scrollbar_thickness + self.scrollbar_margin - self.bb:height())
    else
        return math.max(0, self.content_height + (2 * self.content_margin) - self.bb:height())
    end
end

function ScrollFrame:get_max_h_scroll()
    if self.show_v_scrollbar then
        return math.max(0, self.content_width + (2 * self.content_margin) + self.scrollbar_thickness + self.scrollbar_margin - self.bb:width())
    else
        return math.max(0, self.content_width + (2 * self.content_margin) - self.bb:width())
    end
end

function ScrollFrame:update_layout()
    super().update_layout(self)
    self:update_scroll()
end

function ScrollFrame:update_scroll()
    self:_remove_visual_child(self.v_scrollbar)
    self:_remove_visual_child(self.h_scrollbar)

    if self.content == nil then
        return
    end

    self.frame.bb = BoundingBox(
        self.content_margin - self.h_scroll,
        self.content_margin - self.v_scroll,
        self.content_margin + self.content_width - self.h_scroll,
        self.content_margin + self.content_height - self.v_scroll
    )

    local scrollbar_end_offset = 0
    if self.show_v_scrollbar and self.show_h_scrollbar then
        scrollbar_end_offset = 1
    end

    if self.show_v_scrollbar then

        self.v_scrollbar.x = self.bb:width() - self.scrollbar_margin - self.scrollbar_thickness
        self.v_scrollbar.y = self.scrollbar_margin
        self.v_scrollbar.width = self.scrollbar_thickness
        self.v_scrollbar.height = self.bb:height() - (2 * self.scrollbar_margin) - scrollbar_end_offset

        self.v_scrollbar.handle.width = self.scrollbar_thickness
        self.v_scrollbar.handle.height = clamp(self.bb:height() / self.content_height, 0, 1) * self.v_scrollbar.height
        self.v_scrollbar.handle.y = clamp(self.v_scroll / self.max_v_scroll, 0, 1) * (self.v_scrollbar.height - self.v_scrollbar.handle.height)

        self:_add_visual_child(self.v_scrollbar)
    end

    if self.show_h_scrollbar then
        self.h_scrollbar.x = self.scrollbar_margin
        self.h_scrollbar.y = self.bb:height() - self.scrollbar_margin - self.scrollbar_thickness
        self.h_scrollbar.width = self.bb:width() - (2 * self.scrollbar_margin) - scrollbar_end_offset
        self.h_scrollbar.height = self.scrollbar_thickness

        self.h_scrollbar.handle.width = clamp(self.bb:width() / self.content_width, 0, 1) * self.h_scrollbar.width
        self.h_scrollbar.handle.height = self.scrollbar_thickness
        self.h_scrollbar.handle.x = clamp(self.h_scroll / self.max_h_scroll, 0, 1) * (self.h_scrollbar.width - self.h_scrollbar.handle.width)

        self:_add_visual_child(self.h_scrollbar)
    end
end

require "ui.element"
require "ui.event_sink"
require "ui.containers.frame"

Dialog = {
    event_sink = nil,
    frame = nil,
    sink_updates = nil,
}
setup_class(Dialog, Element)

function Dialog:__init(content)
    super().__init(self)

    self.event_sink = EventSink()
    self.event_sink.bb = BoundingBox(0, 0, 10^32, 10^32)
    self.event_sink.clip = false
    self.frame = Frame()
    self.frame.clip = false

    self.event_sink.keypressed = function(element, key)
        if key == "escape" then
            self:close()
        end
    end

    self.event_sink.mousereleased = function(element, x, y, button)
        if button == 1 and self.close_on_background_click then
            self:close()
        end
        return self.event_sink.enabled
    end

    self:forward_property(self.event_sink, "enabled", nil, "block_interaction")
    self:forward_property(self.event_sink, "background_color", nil, "tint")
    self:forward_property(self.frame, "content")
    self.clip = false
end

function Dialog:get_is_open()
    return nil_coalesce(self:_get_property("is_open"), false)
end

function Dialog:set_is_open(value)
    if not is_type(value, "boolean", "nil")  then
        self:_value_error("Value must be a boolean, or nil.")
    end
    if (value == true) ~= self.is_open then
        if value then
            local parent = self._visual_parent
            if parent ~= nil then
                -- Bring to front (should probably make a better interface for this).
                parent:_remove_visual_child(self)
                parent:_add_visual_child(self)
            end
            self:_add_visual_child(self.event_sink)
            self:_add_visual_child(self.frame)
        else
            self:_clear_visual_children()
        end
    end
    self:_set_property("is_open", value)
end

function Dialog:get_close_on_background_click()
    return nil_coalesce(self:_get_property("close_on_background_click"), false)
end

function Dialog:set_close_on_background_click(value)
    if not is_type(value, "boolean", "nil")  then
        self:_value_error("Value must be a boolean, or nil.")
    end
    self:_set_property("close_on_background_click", value)
end

function Dialog:open()
    self.is_open = true
end

function Dialog:close()
    self.is_open = false
end
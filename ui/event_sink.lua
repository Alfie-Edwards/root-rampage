require "ui.layout_element"

EventSink = {
    -- Captures and blocks all love events.
}
setup_class(EventSink, LayoutElement)

function EventSink:__init()
    super().__init(self)

    self.mousereleased = function() return self.enabled end
    self.mousepressed = function() return self.enabled end
    self.mousemoved = function() return self.enabled end
    self.wheelmoved = function() return self.enabled end
    self.keypressed = function() return self.enabled end
    self.textinput = function() return self.enabled end
end

function EventSink:get_enabled()
    return nil_coalesce(self:_get_property("enabled"), true)
end

function EventSink:set_enabled(value)
    if not is_type(value, "boolean", "nil")  then
        self:_value_error("Value must be a boolean, or nil.")
    end
    self:_set_property("enabled", value)
end


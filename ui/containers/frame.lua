require "ui.element"

Frame = {
    -- An element which composes a single other element.
}
setup_class(Frame, Element)

function Frame:__init(content)
    super().__init(self)

    self.content = content
end

function Frame:set_content(value)
    if not is_type(value, Element, "nil") then
        self:_value_error("Value must be a Element, or nil.")
    end
    if self.content ~= nil then
        self:_clear_visual_children()
    end
    if value ~= nil then
        self:_add_visual_child(value)
    end
    self:_set_property("content", value)
end

function Frame:get_content()
    return self._visual_children[1]
end

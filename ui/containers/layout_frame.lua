require "ui.element"

LayoutFrame = {
    -- An layout element which composes a single other element.
}
setup_class(LayoutFrame, LayoutElement)

function LayoutFrame:__init(content)
    super().__init(self)

    self.content = content
end

function LayoutFrame:set_content(value)
    if not is_type(value, Element, "nil") then
        self:_value_error("Value must be a Element, or nil.")
    end
    if self.content ~= nil then
        self:_clear_visual_children()
    end
    if value ~= nil then
        self:_add_visual_child(value)
    end
end

function LayoutFrame:get_content()
    return self._visual_children[1]
end

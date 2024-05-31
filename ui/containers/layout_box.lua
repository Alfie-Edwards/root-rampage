require "ui.layout_element"

LayoutBox = {
    -- A layout element which contains other elements.
}
setup_class(LayoutBox, LayoutElement)

function LayoutBox:__init(...)
    super().__init(self)

    for _, element in ipairs({...}) do
        self:add(element)
    end
end

function LayoutBox:add(element)
    self:_add_visual_child(element)
end

function LayoutBox:remove(element)
    self:_remove_visual_child(element)
end

function LayoutBox:clear()
    self:_clear_visual_children()
end

function LayoutBox:get_contents()
    return shallow_copy(self._visual_children)
end

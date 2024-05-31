require "ui.element"

Box = {
    -- An element which composes other elements.
}
setup_class(Box, Element)

function Box:__init(...)
    super().__init(self)
    self.clip = false

    for _, element in ipairs({...}) do
        self:add(element)
    end
end

function Box:add(element)
    self:_add_visual_child(element)
end

function Box:remove(element)
    self:_remove_visual_child(element)
end

function Box:clear()
    self:_clear_visual_children()
end

function Box:get_contents()
    return shallow_copy(self._visual_children)
end

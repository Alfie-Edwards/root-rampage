require "ui.containers.layout_frame"

MultiFrame = {
    -- Shows one element att a time.
    -- Add an element under a unique key `swap_frame:add(key, element)`,
    -- then you can swap to showing that element `swap_frame.current = key`.
    items = nil,
}
setup_class(MultiFrame, LayoutFrame)

function MultiFrame:__init(map)
    super().__init(self)
    self.items = {}
end

function MultiFrame:add(key, element)
    self.items[key] = element
    if key == self.current then
        self.content = element
    end
end

function MultiFrame:set_current(value)
    if self:_set_property("current", value) then
        if value == nil then
            self.content = nil
        else
            self.content = self.items[self.current]
        end
    end
end

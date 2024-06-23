require "ui.binding"

Element = {
    _visual_children = nil,
    _visual_parent = nil,
    mouse_pos = nil,
    property_changes = nil,

    cursor = nil,
    bb = nil,
    transform = nil,
    canvas = nil,
    background_color = nil,
    border_color = nil,
    border_thickness = nil,

    textinput = nil,
    keypressed = nil,
    mousepressed = nil,
    mousereleased = nil,
    mousemoved = nil,
    wheelmoved = nil,
}
setup_class(Element, GetterSetterPropertyTable)

function Element:__init()
    super().__init(self)

    self._bindings = {}
    self._visual_children = {}
    self.mouse_pos = {love.mouse.getPosition()}
    self.bb = BoundingBox(0, 0, 0, 0)
    -- self.border_thickness = 2
    -- self.border_color = hsva(love.math.random(), 1, 1, 1)
end

function Element:set_bb(value)
    if not is_type(value, BoundingBox) then
        self:_value_error("Value must be a BoundingBox.")
    end
    self:_set_property("bb", value)
end

function Element:set_transform(value)
    if not is_type(value, "Transform", "nil") then
        self:_value_error("Value must be a love.math.Transform, or nil.")
    end
    self:_set_property("transform", value)
end

function Element:set_keypressed(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element, key) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("keypressed", value)
end

function Element:set_textinput(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element, t) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("textinput", value)
end

function Element:set_mousepressed(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element, x, y, button) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("mousepressed", value)
end

function Element:set_mousereleased(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element, x, y, button) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("mousereleased", value)
end

function Element:set_mousemoved(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element, x, y, dx, dy) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("mousemoved", value)
end

function Element:set_wheelmoved(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element, x, y) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("wheelmoved", value)
end

function Element:set_cursor(value)
    if not is_type(value, "Cursor", "nil") then
        self:_value_error("Value must be a love.mouse.Cursor, or nil.")
    end
    self:_set_property("cursor", value)
end

function Element:get_clip()
    return nil_coalesce(self:_get_property("clip"), true)
end

function Element:set_clip(value)
    if not is_type(value, "boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    self:_set_property("clip", value)
end

function Element:get_background_color()
    return nil_coalesce(self:_get_property("background_color"), {0, 0, 0, 0})
end

function Element:set_background_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("background_color", value)
end

function Element:get_border_color()
    return nil_coalesce(self:_get_property("border_color"), {0, 0, 0, 0})
end

function Element:set_border_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("border_color", value)
end

function Element:get_border_thickness()
    return nil_coalesce(self:_get_property("border_thickness"), 0)
end

function Element:set_border_thickness(value)
    if not is_type(value, "number", "nil") then
        self:_value_error("Value must be a number, or nil.")
    end
    self:_set_property("border_thickness", value)
end

function Element:has_binding(property_name)
    if not self:_is_property(property_name) then
        error("\""..property_name.."\" is not a property of "..type_string(self)..".")
    end
    return self._bindings[property_name] ~= nil
end

function Element:bind(property_name, binding)
    if not self:_is_property(property_name) then
        error("\""..property_name.."\" is not a property of "..type_string(self)..".")
    end
    if self:has_binding(property_name) then
        self:unbind(property_name)
    end
    if binding.src == nil or binding.src_prop == nil then
        error("Attempted to bind property "..property_name.." of "..type_string(self)..", but the binding has no source set.")
    end
    binding.dst = self
    binding.dst_prop = property_name
    self._bindings[property_name] = binding
    binding:apply()
end

function Element:unbind(property_name)
    if not self:_is_property(property_name) then
        error("\""..property_name.."\" is not a property of "..type_string(self)..".")
    end
    if self._bindings[property_name] ~= nil then
        self._bindings[property_name].dst = nil
        self._bindings[property_name]:unbind()
        self._bindings[property_name] = nil
    end
end

function Element:contains(x, y)
    return (x > 0) and (y > 0) and (x < self.bb:width() - 1) and (y < self.bb:height() - 1)
end

function Element:forward_property(element, property_name, converter, forward_name)
    if not is_type(element, Element) then
        error("Expected element to be an Element, got "..details_string(element)..".")
    end
    if not is_type(property_name, "string") then
        error("Expected property_name to be a string, got "..details_string(property_name)..".")
    end

    if not element:_is_property(property_name) then
        error("\""..property_name.."\" is not a property of "..type_string(element)..".")
    end

    forward_name = nil_coalesce(forward_name, property_name)

    if converter ~= nil then
        self["get_"..forward_name] = function()
            return converter.convert(element[property_name])
        end
        if element:_get_setter(property_name) ~= nil then
            self["set_"..forward_name] = function(value)
                element[property_name] = converter.convert_back(value)
            end
        end
        element.property_changed:subscribe(
            function(e, n, old_value, new_value)
                if e == element and n == property_name then
                    local converted_old_value = converter.convert(old_value)
                    local converted_new_value = converter.convert(new_value)
                    if (converted_old_value ~= converted_new_value) or (old_value == new_value) then
                        self:property_changed(forward_name, converted_old_value, converted_new_value)
                    end
                end
            end
        )
    else
        self["get_"..forward_name] = function(self)
            return element[property_name]
        end
        if element:_get_setter(property_name) ~= nil then
            self["set_"..forward_name] = function(self, value)
                element[property_name] = value
            end
        end
        element.property_changed:subscribe(
            function(e, n, old_value, new_value)
                if e == element and n == property_name then
                    self:property_changed(forward_name, old_value, new_value)
                end
            end
        )
    end
end

function Element:_add_visual_child(child)
    -- Add a child in the visual tree.
    -- These methods should not be used as a user-facing interface for managing composition.
    -- Elements with settable content should provide their own interface (see continers).
    -- Complexity in the visual tree should be a hidden implementation detail.
    
    if not is_type(child, "Element") then
        error("Expected child to be an Element, got "..details_string(child)..".")
    end

    table.insert(self._visual_children, child)
    child._visual_parent = self
end

function Element:_remove_visual_child(child)
    if not is_type(child, "Element") then
        error("Expected child to be an Element, got "..details_string(child)..".")
    end

    if child._visual_parent == self then
        remove_value(self._visual_children, child)
        child._visual_parent = nil
    end
end

function Element:_clear_visual_children()
    for _, child in ipairs(self._visual_children) do
        child._visual_parent = nil
    end
    self._visual_children = {}
end

function Element:__newindex(name, value)
    if is_type(value, Binding) and self:_is_property(name) then
        self:bind(name, value)
        return
    end

    super().__newindex(self, name, value)
end

function Element:update(dt)
    -- do nothing
end

function Element:draw()
    -- Draw background.
    if self.background_color[4] > 0 then
        love.graphics.setColor(self.background_color)
        love.graphics.rectangle("fill", 0, 0, self.bb:width(), self.bb:height())
    end
    if self.border_thickness > 0 and self.border_color[4] > 0 then
        love.graphics.setColor(self.border_color)
        love.graphics.setLineWidth(self.border_thickness)
        local w = math.max(0, self.bb:width() - self.border_thickness)
        local h = math.max(0, self.bb:height() - self.border_thickness)
        love.graphics.rectangle("line", self.border_thickness / 2, self.border_thickness / 2, w, h)
    end
end

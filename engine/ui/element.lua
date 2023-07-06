require "utils"

Element = {
    parent = nil,
    children = nil,
    mouse_pos = nil,
    property_changes = nil,

    cursor = nil,
    bb = nil,
    keypressed = nil,
    click = nil,
    mousemove = nil,
}
setup_class(Element)

function Element.new()
    local obj = {}

    obj.children = {}
    obj.mouse_pos = {love.mouse.getPosition()}
    obj.property_changed = Event.new() -- (element, property_name, old_value, new_value)

    -- Closure so properties can only accessed through _get_property and _set_property.
    local properties_closure = {}
    obj._get_property = function(self, name)
        return properties_closure[name]
    end
    obj._set_property = function(self, name, value)
        local old_value = properties_closure[name]
        if old_value == value then
            return false
        end

        properties_closure[name] = value
        self:property_changed(name, old_value, new_value)
        return true
    end

    setup_instance(obj, Element)

    obj.bb = BoundingBox.new(0, 0, 0, 0)

    return obj
end

function Element:get_mouse_pos()
    return self.mouse_pos[1], self.mouse_pos[2]
end

function Element:set_bb(value)
    if type_string(value) ~= "BoundingBox" then
        self:_value_error("Value must be a BoundingBox.")
    end
    self:_set_property("bb", value)
end

function Element:set_transform(value)
    if not value_in(type_string(value), {"Transform", "nil"}) then
        self:_value_error("Value must be a love.math.Transform, or nil.")
    end
    self:_set_property("transform", value)
end

function Element:set_keypressed(value)
    if not value_in(type_string(value), {"function", "nil"}) then
        self:_value_error("Value must be a function with the signature (key) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("keypressed", value)
end

function Element:set_click(value)
    if not value_in(type_string(value), {"function", "nil"}) then
        self:_value_error("Value must be a function with the signature (x, y, button) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("click", value)
end

function Element:set_mousemove(value)
    if not value_in(type_string(value), {"function", "nil"}) then
        self:_value_error("Value must be a function with the signature (x, y, dx, dy) => bool (returns whether to consume the event), or nil.")
    end
    self:_set_property("mousemove", value)
end

function Element:set_cursor(value)
    if not value_in(type_string(value), {"Cursor", "nil"}) then
        self:_value_error("Value must be a love.mouse.Cursor, or nil.")
    end
    self:_set_property("cursor", value)
end

function Element:contains(x, y)
    return (x > 0) and (y > 0) and (x < self.bb:width()) and (y < self.bb:height())
end

function Element:add_child(child)
    assert(child ~= nil)
    table.insert(self.children, child)
    child.parent = self
end

function Element:remove_child(child)
    assert(child ~= nil)
    if child.parent == self then
        remove_value(self.children, child)
        child.parent = nil
    end
end

function Element:clear_children()
    for _, child in ipairs(self.children) do
        assert(child.parent == self)
        child.parent = nil
    end
    self.children = {}
end

function Element:set_properties(properties)
    -- Helper for setting multiple properties at once
    for name,value in pairs(properties) do
        local setter = self["set_"..name]
        if setter == nil then
            error("Element of type "..type_string(self).." does not have a setter for the property '"..name.."'.")
        end
        setter(self, value)
    end
end

function Element:update(dt)
    -- do nothing
end

function Element:draw()
    -- do nothing
end

function Element:_value_error(message)
    if message == nil then
        message = ""
    end

    local property = "???"
    local info = debug.getinfo(2, 'f')
    if info ~= nil and info.func ~= nil then
        local setter_name = get_key(self, info.func)
        if setter_name ~= nil and string.sub(setter_name, 1, 4) == "set_" then
            property = string.sub(setter_name, 5, -1)
        end
    end

    local default = {}
    setmetatable(default, {__tostring = function() return "???" end})
    local value = get_local("value", default, 3)
    if type(value) == "string" then
        value = '"'..value..'"'
    end

    error("Invalid value ("..tostring(value)..") for property \""..property.."\" of "..type_string(self).." element. "..tostring(message))
end

-- Getting properties as element.prop will call through to element:_get_property(prop).
function Element:__index(name)
    return self:_get_property(name)
end

-- Setting properties as element.prop = val will call through to state:set_prop(val).
function Element:__newindex(name, value)
    local setter = self["set_"..name]
    if setter ~= nil then
        -- Use property setter if there is one available.
        setter(self, value)
        return
    end

    -- Temporarily remove metatable to allow value to be set directly.
    local mt = getmetatable(self)
    setmetatable(self, {})
    self[name] = value
    setmetatable(self, mt)
end

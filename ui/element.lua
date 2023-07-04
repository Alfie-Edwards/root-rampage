require "utils"

Element = {
    parent = nil,
    children = nil,
    cursor = nil,
    bb = nil,
    keypressed = nil,
    click = nil,
    mousemove = nil,
    mouse_pos = nil,
}
setup_class(Element)

function Element.new()
    local obj = magic_new()

    obj.children = {}
    obj.bb = BoundingBox.new(0, 0, 0, 0)
    obj.mouse_pos = {love.mouse.getPosition()}

    return obj
end

function Element:get_transform()
    return self.transform
end

function Element:set_transform(value)
    if not value_in(type_string(value), {"Transform", "nil"}) then
        self:_value_error("Value must be a love.math.Transform, or nil.")
    end
    self.transform = value
end

function Element:get_mouse_pos()
    return self.mouse_pos[1], self.mouse_pos[2]
end

function Element:get_keypressed()
    return self.keypressed
end

function Element:set_keypressed(value)
    if not value_in(type(value), {"function", "nil"}) then
        self:_value_error("Value must be a function with the signature (key) => bool (returns whether to consume the event), or nil.")
    end
    self.keypressed = value
end

function Element:get_click()
    return self.click
end

function Element:set_click(value)
    if not value_in(type(value), {"function", "nil"}) then
        self:_value_error("Value must be a function with the signature (x, y, button) => bool (returns whether to consume the event), or nil.")
    end
    self.click = value
end

function Element:get_mousemove()
    return self.mousemove
end

function Element:set_mousemove(value)
    if not value_in(type(value), {"function", "nil"}) then
        self:_value_error("Value must be a function with the signature (x, y, dx, dy) => bool (returns whether to consume the event), or nil.")
    end
    self.mousemove = value
end

function Element:get_cursor()
    return self.cursor
end

function Element:set_cursor(cursor)
    if not value_in(type_string(value), {"Cursor", "nil"}) then
        self:_value_error("Value must be a love.mouse.Cursor, or nil.")
    end
    self.cursor = cursor
end

function Element:update(dt)
    -- do nothing
end

function Element:draw()
    -- do nothing
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

function Element:set_properties(properties)
    -- Helper for setting multiple properties at once
    for name,value in pairs(properties) do
        local setter_name = "set_"..name
        if self[setter_name] == nil then
            error("Element of type "..type_string(self).." does not have a setter for the property '"..name.."'.")
        end
        self[setter_name](self, value)
    end
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

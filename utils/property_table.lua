NONE = {
    -- Set a property to this and the value will still be nil but it will show up during iteration.
}

PropertyTable = {
    -- It can be interacted with like any normal table.
    -- Has a property_changed event to track changes.
    -- Has a nice tostring which lists all of the properties (recursively for states within states).
    property_changed = nil,
}
setup_class(PropertyTable)

function PropertyTable:__init(properties)
    super().__init(self)

    -- Closure so properties can only accessed through _get_property and _set_property.
    local properties_closure = {}
    if properties ~= nil then
        properties_closure = shallow_copy(properties)
    end

    -- Temporarily disable metatable to set values directly.
    without_metatable(self, function()

        self.property_changed = Event() -- (PropertyTable, property_name, old_value, new_value)

        self._get_property = function(self, name)
            return self:__get_property(name, properties_closure)
        end

        self._set_property = function(self, name, value)
            return self:__set_property(name, value, properties_closure)
        end

        self._get_property_names = function(self)
            return self:__get_property_names(properties_closure)
        end

        self._is_property = function(self, name)
            return self:__is_property(name, properties_closure)
        end

    end)
end

function PropertyTable:_get_getters()
    -- Helper for enumerating the getters of this instance.
    local result = {}

    -- Default iteration to see actual members of this table.
    for key, _ in BaseObjectClass.__pairs(self) do
        if type(key) == "string" and #key > 4 and string.sub(key, 1, 4) == "get_" then
            result[string.sub(key, 5, -1)] = self[key]
        end
    end
    return result
end

function PropertyTable:_get_setters()
    -- Helper for enumerating the setters of this instance.
    local result = {}

    -- Default iteration to see actual members of this table.
    for key, value in BaseObjectClass.__pairs(self) do
        if type(key) == "string" and #key > 4 and string.sub(key, 1, 4) == "set_" then
            result[string.sub(key, 5, -1)] = value
        end
    end
    return result
end

function PropertyTable:_get_getter(name)
    -- Helper for finding a getter, importantly bypasses __index.
    if type(name) ~= "string" then
        return nil
    end
    local name = "get_"..name
    -- Default iteration to see actual members of this table.
    for key, value in BaseObjectClass.__pairs(self) do
        if key == name then
            if type(value) == "function" and debug.getinfo(value).nparams == 1 then
                return value
            else
                return nil
            end
        end
    end
    return nil
end

function PropertyTable:_get_setter(name)
    -- Helper for finding a setter, importantly bypasses __index.
    if type(name) ~= "string" then
        return nil
    end
    local name = "set_"..name
    -- Default iteration to see actual members of this table.
    for key, value in BaseObjectClass.__pairs(self) do
        if key == name then
            if type(value) == "function" and debug.getinfo(value).nparams == 2 then
                return value
            else
                return nil
            end
        end
    end
    return nil
end

function PropertyTable:set(properties_or_name, value)
    -- Helper for setting properties.
    -- Useful for checking that what you are setting is a valid property,
    -- or for setting multiple properties in a clear block.
    local properties = properties_or_name
    if type(properties_or_name) == "string" then
        properties = { properties_or_name = value }
    end
    for name, value in pairs(properties) do
        if not self:_is_property(name) then
            error("\""..name.."\" is not a property of "..type_string(self)..".")
        end
        self[name] = value
    end
end

function PropertyTable:_value_error(message, property_name, value)
    if message == nil then
        message = ""
    end

    if property_name == nil then
        local info = debug.getinfo(2, 'f')
        if info ~= nil and info.func ~= nil then
            local setter_name = get_key(self, info.func, template_pairs)
            if setter_name ~= nil and string.sub(setter_name, 1, 4) == "set_" then
                property_name = string.sub(setter_name, 5, -1)
            end
        end
    end
    property_name = nil_coalesce(property_name, "???")

    if value == nil then
        local default = {}
        setmetatable(default, {__tostring = function() return "???" end})
        value = get_local("value", default, 3)
    end

    error("Invalid value ("..details_string(value)..") for property \""..property_name.."\" of "..type_string(self)..". "..tostring(message))
end

function PropertyTable:__get_property(name, properties_closure)
    -- Custom metamethod, can be overridden in subclasses
    -- Control how the properties closure is accessed.
    local value = properties_closure[name]
    if value == NONE then
        value = nil
    end
    return value
end

function PropertyTable:__set_property(name, value, properties_closure)
    -- Custom metamethod, can be overridden in subclasses
    -- Control how the properties closure is mutated.
    local old_value = properties_closure[name]
    if old_value == value then
        return false
    end

    properties_closure[name] = nil_coalesce(value, NONE)
    self:property_changed(name, old_value, value)
    return true
end

function PropertyTable:__get_property_names(properties_closure)
    -- Custom metamethod, can be overridden in subclasses.
    -- Controls what shows up in iteration.
    return keys_to_set(properties_closure)
end

function PropertyTable:__is_property(name, properties_closure)
    -- Custom metamethod, can be overridden in subclasses.
    -- Defined what counts as a property when accessing / mutating.
    return true
end

-- Getting properties as x.prop will call through to x:get_prop() or x:_get_property(prop).
function PropertyTable:__index(name)
    if not self:_is_property(name) then
        return nil
    end

    local getter = self:_get_getter(name)
    if getter ~= nil then
        -- Use getter if there is one.
        return getter(self)
    end

    -- Fallback to calling _get_property directly.
    return self:_get_property(name)
end

-- Setting properties as x.prop = val will call through to x:set_prop(val) or x:_set_property(val).
function PropertyTable:__newindex(name, value)
    if not self:_is_property(name) then
        -- Temporarily disable metatable to allow set value directly.
        without_metatable(self, function() self[name] = value end)
        return
    end

    local setter = self:_get_setter(name)
    if setter ~= nil then
        -- Use setter if there is one available.
        setter(self, value)
        return
    end

    -- Fallback to calling _set_property directly.
    self:_set_property(name, value)
end

-- Iterate over properties.
function PropertyTable:__pairs()
    local i, property_name
    return function(t, k)
        i, property_name = next(t, i)
        if property_name == nil then
            return nil, nil
        end
        return property_name, self[property_name]
    end, set_to_sorted_list(self:_get_property_names()), nil
end

function PropertyTable:__tostring()
    if debug.getinfo(6, "f").func == PropertyTable.__tostring then
        -- Truncate resursive calls to 3 levels.
        return "... ("..type_string(self)..")"
    end

    local result = type_string(self).." {"
    for name, value in pairs(self) do
        value = string.gsub(details_string(value), "\n", "\n    ")
        result = result.."\n    "..name..": "..value
    end
    if iter_size(self) > 0 then
        result = result.."\n"
    end
    result = result.."}"
    return result
end

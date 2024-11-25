FixedPropertyTable = {
    -- An object with a fixed set of properties specified on construction.
    -- Only these properties may be get/set, anything else will error.
}
setup_class(FixedPropertyTable, PropertyTable)

function FixedPropertyTable:__init(properties)
    assert(properties ~= nil)
    super().__init(self, properties)
end

function FixedPropertyTable:__get_property(name, properties_closure)
    -- Override __get_property error on unknowns.

    if not self:_is_property(name) then
        for k, v in pairs(self:_get_property_names()) do
            print(k, v)
        end
        error(details_string(name).." is not a property of "..type_string(self)..".")
    end
    return PropertyTable.__get_property(self, name, properties_closure)
end

function FixedPropertyTable:__set_property(name, value, properties_closure)
    -- Override __set_property error on unknowns.

    if not self:_is_property(name) then
        for k, v in pairs(self:_get_property_names()) do
            print(k, v)
        end
        error("\""..name.."\" is not a property of "..type_string(self)..".")
    end
    return PropertyTable.__set_property(self, name, value, properties_closure)
end

function FixedPropertyTable:__is_property(name, properties_closure)
    -- Override __is_property to count only things which already have values.
    return properties_closure[name] ~= nil
end

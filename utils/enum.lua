Enum = {
    _values = nil
}

setup_class(Enum)

function Enum:__init(...)
    super().__init(self)

    without_metatable(self, function(...)
        self._values = set(...)
    end, ...)

    for _, value in pairs(self) do
        if not type(value) == "string" then
            error("Invalid type for enum value \""..type(value).."\". Enum values must be strings.")
        end
    end
end

function Enum:values_list()
    return set_to_sorted_list(self._values)
end

function Enum:is(x)
    return self._values[x]
end

function Enum:__index(key)
    if self._values[key] then
        return key
    end

    local name = get_key(_G, self) or "this enum"
    error(tostring(key).." is not a member of "..name..". Valid members are "..tostring(self)..".")
end

function Enum:__newindex(key, value)
    error("Cannot assign to an enum.")
end

function Enum:__pairs()
    return function(t, k)
        k, _ = next(self._values, k)
        return k, k
    end, self, nil
end

function Enum:__tostring()
    local name = get_key(_G, self)
    local result = ""
    if name then
        result = result..name.." "
    end
    result = result.."{ "
    for _, value in pairs(self) do
        result = result..value.." "
    end
    result = result.."}"

    return result
end

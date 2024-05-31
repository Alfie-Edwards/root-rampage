HashMap = {
    -- Works with a custom metamethod __hash.
}
setup_class(HashMap)

function HashMap:__init(items)
    super().__init(self)

    if items then
        for key, value in pairs(items) do
            self[key] = value
        end
    end
end

function HashMap:contains_key(key)
    return self[key] ~= nil
end

function HashMap:__pairs()
    local key_hash, entry
    return function(t, k)
        key_hash, entry = next(self, key_hash)
        if entry == nil then
            return nil, nil
        end
        return entry.key, entry.value
    end, self, nils
end

function HashMap:__index(key)
    if not hashable(key) then
        error("Invalid key type ("..type_string(key).."). Keys in a hashmap must implement the custom __hash metatable method.")
    end

    return without_metatable(self, function()
        return get_if_not_nil(self[hash(key)], "value")
    end)
end

function HashMap:__newindex(key, value)
    if not hashable(key) then
        error("Invalid key type ("..type_string(key).."). Keys in a hashmap must implement the custom __hash metatable method.")
    end

    -- Temporarily unset metatable to allow direct access.
    without_metatable(self, function()
        if value ~= nil then
            self[hash(key)] = {key = key, value = value}
        else
            self[hash(key)] = nil
        end
    end)
end

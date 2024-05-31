HashSet = {
    -- Works with a custom metamethod __hash.
}
setup_class(HashSet)

function HashSet:__init(...)
    super().__init(self)

    for _, item in ipairs({...}) do
        self:add(item)
    end
end

function HashSet:contains(item)
    return self[item]
end

function HashSet:add(item)
    self[item] = true
end

function HashSet:remove(item)
    self[item] = false
end

function HashSet:__pairs()
    local key_hash, item
    return function(t, k)
        key_hash, item = next(self, key_hash)
        return item, true
    end, self, nil
end

function HashSet:__index(item)
    if not hashable(item) then
        error("Invalid item type ("..type_string(key).."). Items in a hashset must implement the custom __hash metatable method.")
    end

    return without_metatable(self, function()
        return self[hash(item)] ~= nil
    end)
end

function HashSet:__newindex(item, value)
    if not hashable(item) then
        error("Invalid item type ("..type_string(key).."). Items in a hashset must implement the custom __hash metatable method.")
    end
    if not is_type(value, "boolean", nil) then
        error("Invalid value type ("..type_string(value).."). Values must be a boolean or nil. True to add the item, false or nil to remove it.")
    end

    -- Temporarily unset metatable to allow direct access.
    without_metatable(self, function()
        if value then
            self[hash(item)] = item
        else
            self[hash(item)] = nil
        end
    end)
end

function HashSet:__add(other)
    -- Union.
    assert(is_type(other, HashSet))

    local result = HashSet()
    for item, _ in pairs(self) do
        result:add(item)
    end
    for item, _ in pairs(other) do
        result:add(item)
    end
    return result
end

function HashSet:__sub(other)
    -- All items in a but not in b.
    assert(is_type(other, HashSet))

    local result = HashSet()
    for item, _ in pairs(self) do
        result:add(item)
    end
    for item, _ in pairs(other) do
        result:remove(item)
    end
    return result
end

function HashSet:__mul(other)
    -- Intersection.
    assert(is_type(other, HashSet))

    local result = HashSet()
    for item, _ in pairs(self) do
        if other[item] then
            result:add(item)
        end
    end
    return result
end

function HashSet:__div(other)
    -- All items only in a or only in b.
    assert(is_type(other, HashSet))

    return self + other - (self * other)
end

function list_to_set(t)
    local result = {}
    for _, v in ipairs(t) do
        result[v] = true
    end
    return result
end

function set(...)
    return list_to_set({...})
end

function keys_to_set(t)
    local result = {}
    for k, _ in pairs(t) do
        result[k] = true
    end
    return result
end

function values_to_set(t)
    local result = {}
    for _, v in pairs(t) do
        result[v] = true
    end
    return result
end

function is_set(t)
    if t == nil or type(t) ~= "table" then
        return false
    end
    for _, v in pairs(t) do
        if v ~= true then
            return false
        end
    end
    return true
end

function set_to_sorted_list(s, sort_function)
    return keys_to_sorted_list(s, sort_function)
end
